#!/usr/bin/env bash
# Creates the remote backend (separate RG + storage account + container) and registers Azure providers.
set -euo pipefail
cd "$(dirname "$0")/.."

PROJ_DIR="$(ls -d project-* | head -n1)"
ID="${PROJ_DIR#project-}"
if [ "$ID" = "HUMBERID" ]; then
  echo "ERROR: run ./scripts/configure.sh first"
  exit 1
fi

OWNER="$(grep '^tag_name' "$PROJ_DIR/terraform.tfvars" | cut -d'"' -f2)"
RG="rg-tfstate-${ID}"
SA="tfstate${ID}ccgc5502"
LOC="canadacentral"

echo "Registering resource providers (takes a few minutes the first time)..."
for p in Microsoft.Compute Microsoft.Network Microsoft.Storage Microsoft.OperationalInsights \
         Microsoft.RecoveryServices Microsoft.DBforPostgreSQL Microsoft.Insights; do
  az provider register --namespace "$p" --wait
done

az group create --name "$RG" --location "$LOC" \
  --tags Project="CCGC 5502 Terraform Project" Name="$OWNER" ExpirationDate="2027-12-31" Environment="Learning" >/dev/null

az storage account create --name "$SA" --resource-group "$RG" --location "$LOC" \
  --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false \
  --tags Project="CCGC 5502 Terraform Project" Name="$OWNER" ExpirationDate="2027-12-31" Environment="Learning" >/dev/null

KEY="$(az storage account keys list --resource-group "$RG" --account-name "$SA" --query '[0].value' -o tsv)"
az storage container create --name tfstate --account-name "$SA" --account-key "$KEY" >/dev/null

echo "Backend ready: RG=$RG  Storage=$SA  Container=tfstate"
