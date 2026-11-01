#!/usr/bin/env bash
# Tests REAL deployments (3 Linux zonal VMs + 1 Windows VM) and writes the first
# region / VM size / PostgreSQL SKU that really works into terraform.tfvars.
# Usage (from the ccgc5502-terraform-project folder): bash scripts/find-working-config.sh [regions...]
set -uo pipefail
cd "$(dirname "$0")/.."
PROJ="$(ls -d project-*/ | head -n1)"; PROJ="${PROJ%/}"; ID="${PROJ#project-}"
TFVARS="$PROJ/terraform.tfvars"
REGIONS="${*:-canadacentral centralus eastus2 westus3 uksouth centralindia}"
LIN_IMG="Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest"
WIN_IMG="MicrosoftWindowsServer:WindowsServer:2022-datacenter-g2:latest"
PW="Probe#2026-Ccgc5502x"
TMP="$(mktemp -d)"; PROBE_RG=""
trap '[ -n "$PROBE_RG" ] && az group delete -n "$PROBE_RG" --yes --no-wait -o none 2>/dev/null' EXIT

az account show >/dev/null 2>&1 || { echo "Run: az login --use-device-code"; exit 1; }
if [ "$(az group exists --name "${ID}-RG" | tr -d '\r')" = "true" ]; then
  echo "STOP: resource group ${ID}-RG still exists. Run 'terraform destroy --auto-approve' first (inside $PROJ)."
  exit 1
fi

echo "Step 1/3: reading what Azure offers you in: $REGIONS (1-3 minutes)..."
for r in $REGIONS; do
  ( az vm list-skus -l "$r" --resource-type virtualMachines --all -o json 2>/dev/null | tr -d '\r' > "$TMP/$r.skus"
    az vm list-usage -l "$r" -o json 2>/dev/null | tr -d '\r' > "$TMP/$r.usage"
    az postgres flexible-server list-skus -l "$r" -o json 2>/dev/null | tr -d '\r' > "$TMP/$r.pg" ) &
done
wait

python3 - "$TMP" "$REGIONS" <<'PY'
import json, sys, re
tmp, regions = sys.argv[1], sys.argv[2].split()
NEED = 8
TIER = {"Burstable": "B", "GeneralPurpose": "GP", "MemoryOptimized": "MO"}
PREF = [("Burstable", "Standard_B1ms"), ("GeneralPurpose", "Standard_D2ds_v4"), ("GeneralPurpose", "Standard_D2s_v3"),
        ("GeneralPurpose", "Standard_D2ds_v5"), ("GeneralPurpose", "Standard_D2ads_v5")]
def load(p):
    try:
        return json.load(open(p))
    except Exception:
        return None
def walk(o, tier, out):
    if isinstance(o, list):
        for x in o: walk(x, tier, out)
    elif isinstance(o, dict):
        t = o.get("tier") or tier
        n = o.get("name")
        if isinstance(n, str) and n.startswith("Standard_"):
            out.append((t, n))
        if n in TIER: t = n
        for v in o.values():
            if isinstance(v, (list, dict)): walk(v, t, out)
lines = []
for r in regions:
    skus, usage, pg = load(f"{tmp}/{r}.skus"), load(f"{tmp}/{r}.usage"), load(f"{tmp}/{r}.pg")
    if not skus or not usage:
        print(f"  {r}: no data (skipped)"); continue
    fam, total = {}, 0
    for u in usage:
        k = u["name"]["value"].lower(); free = int(u["limit"]) - int(u["currentValue"]); fam[k] = free
        if k == "cores": total = free
    pairs = []
    if pg: walk(pg, None, pairs)
    db = next((f"{TIER[t]}_{n}" for t, n in PREF if (t, n) in pairs and t in TIER), None)
    if not db:
        db = next((f"GP_{n}" for t, n in pairs if t == "GeneralPurpose" and "_D2" in n), None)
    if not db:
        print(f"  {r}: no PostgreSQL size offered (skipped)"); continue
    c = []
    for s in skus:
        if s.get("resourceType") != "virtualMachines": continue
        caps = {x["name"]: x["value"] for x in s.get("capabilities", [])}
        if caps.get("vCPUs") != "2" or float(caps.get("MemoryGB", "0") or 0) < 4: continue
        if "V2" not in caps.get("HyperVGenerations", "") or "SCSI" not in caps.get("DiskControllerTypes", "SCSI"): continue
        if caps.get("CpuArchitectureType", "x64").lower() != "x64" or "Promo" in s["name"]: continue
        bad, locbad = set(), False
        for x in s.get("restrictions", []):
            if x.get("type") == "Location": locbad = True
            elif x.get("type") == "Zone": bad.update(x.get("restrictionInfo", {}).get("zones", []))
        if locbad: continue
        zones = set()
        for li in s.get("locationInfo", []): zones.update(li.get("zones", []))
        if not {"1", "2", "3"} <= (zones - bad): continue
        if fam.get((s.get("family") or "").lower(), 0) < NEED or total < NEED: continue
        n = s["name"]
        rank = 0 if "_v5" in n else 1 if "_v4" in n else 2 if "_v3" in n else 3 if n.startswith("Standard_B") else 4
        c.append((rank, n))
    c.sort()
    print(f"  {r}: {len(c)} usable VM sizes, database option {db}")
    lines += [f"{r} {n} {db}" for _, n in c]
open(tmp + "/cands.txt", "w").write("\n".join(lines))
PY

mapfile -t CANDS < "$TMP/cands.txt"
if [ "${#CANDS[@]}" -eq 0 ]; then echo "No usable combination found. Send this output to your assistant."; exit 1; fi

probe() {
  local R="$1" S="$2" z bad=0 t=0 ok=0 fail=0
  PROBE_RG="probe-${ID}-$RANDOM"
  az group create -n "$PROBE_RG" -l "$R" -o none || return 1
  az network vnet create -g "$PROBE_RG" -n pv -l "$R" --address-prefix 10.9.0.0/16 --subnet-name ps --subnet-prefix 10.9.1.0/24 -o none || bad=1
  if [ $bad -eq 0 ]; then
    for z in 1 2 3; do
      az vm create -g "$PROBE_RG" -n "pl$z" --image "$LIN_IMG" --size "$S" --zone "$z" --admin-username azureadmin \
        --admin-password "$PW" --authentication-type password --vnet-name pv --subnet ps --public-ip-address "" --nsg "" \
        --no-wait -o none 2>>"$TMP/err.log" || bad=1
    done
    az vm create -g "$PROBE_RG" -n pw1 --image "$WIN_IMG" --size "$S" --admin-username azureadmin --admin-password "$PW" \
      --vnet-name pv --subnet ps --public-ip-address "" --nsg "" --no-wait -o none 2>>"$TMP/err.log" || bad=1
  fi
  while [ $bad -eq 0 ] && [ $t -lt 1200 ]; do
    ok="$(az vm list -g "$PROBE_RG" --query "length([?provisioningState=='Succeeded'])" -o tsv 2>/dev/null | tr -d '\r')"
    fail="$(az deployment group list -g "$PROBE_RG" --query "length([?properties.provisioningState=='Failed'])" -o tsv 2>/dev/null | tr -d '\r')"
    [ "${ok:-0}" -ge 4 ] && break
    [ "${fail:-0}" -gt 0 ] && { bad=1; break; }
    sleep 20; t=$((t+20))
  done
  [ "${ok:-0}" -lt 4 ] && bad=1
  echo "    cleaning up the test VMs (a few minutes)..."
  az group delete -n "$PROBE_RG" --yes -o none 2>/dev/null
  PROBE_RG=""
  return $bad
}

echo "Step 2/3: testing real deployments, best candidates first (cleans up after each test)..."
n=0
for line in "${CANDS[@]}"; do
  [ -z "$line" ] && continue
  n=$((n+1)); [ $n -gt 8 ] && break
  read -r R S D <<<"$line"
  echo "  [$n] testing $R / $S ..."
  : > "$TMP/err.log"
  if probe "$R" "$S"; then
    echo "Step 3/3: it works. Writing settings into $TFVARS"
    sed -i "s/^location .*/location        = \"$R\"/" "$TFVARS"
    sed -i "s/^vm_size .*/vm_size          = \"$S\"/" "$TFVARS"
    if grep -q '^db_sku_name' "$TFVARS"; then sed -i "s/^db_sku_name.*/db_sku_name      = \"$D\"/" "$TFVARS"; else echo "db_sku_name      = \"$D\"" >> "$TFVARS"; fi
    echo; echo "READY:  region=$R  vm_size=$S  database=$D"; grep -E '^(location|vm_size|db_sku_name)' "$TFVARS"
    exit 0
  fi
  echo "    failed: $(grep -m1 -o 'SkuNotAvailable[^.]*\|QuotaExceeded[^.]*\|exceeding approved[^.]*\|not available[^.]*' "$TMP/err.log" | head -c 140)"
done
echo "None of the tested combinations worked. Send this output to your assistant."
exit 1
