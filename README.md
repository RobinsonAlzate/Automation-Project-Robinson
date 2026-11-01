# CCGC 5502 – Terraform Project (Azure)

**Student:** Robinson Alzatte  |  **Humber ID (last 4):** 8935  |  **GitHub:** https://github.com/RobinsonAlzate/Automation-Project-Robinson

## What this project does (short)
Terraform code that builds, in one command, a complete Azure environment in **Central US**:
a resource group, a virtual network + subnet + NSG (ports 22, 3389, 5985, 80), a Log Analytics workspace, a Recovery Services vault and a storage account,
**3 Linux VMs** (one per availability zone, built with `for_each`), **1 Windows Server 2022 VM** (built with `count`, in an availability set),
one 10 GB data disk per VM, a **load balancer** in front of the Linux VMs, and a **PostgreSQL flexible server**.
A null provisioner (`remote-exec`) prints the hostname of every Linux VM during the deployment.
The code is split into 8 child modules (`rgroup`, `network`, `common`, `vmlinux`, `vmwindows`, `datadisk`, `loadbalancer`, `database`) and one root module (`project-8935`).
The Terraform state is stored in a remote backend (an Azure storage account that is never destroyed). A correct run creates **48 resources**.

## Key information (everything needed is already inside the code)
| Item | Value |
|---|---|
| Azure subscription | `Robinson_Subscription` – ID `8c8941f9-9a8e-4c24-a1f8-60fc998da3c3` |
| Region / VM size | `centralus` / `Standard_E2bds_v5` |
| Linux OS | Ubuntu 22.04 LTS (see note at the bottom) |
| VM admin user / password | `azureadmin` / `Ccgc5502#Terraform2026` |
| PostgreSQL admin user / password | `pgadmin` / `Ccgc5502#Postgres2026` |
| Remote backend | resource group `rg-tfstate-8935`, storage account `tfstate8935ccgc5502`, container `tfstate` |
| Resource group created by Terraform | `8935-RG` |
| Tags | Project=`CCGC 5502 Terraform Project`, Name=`robinson.alzatte`, ExpirationDate=`2027-12-31`, Environment=`Learning` |
| GitHub token | NOT stored here (secret). Only needed to clone the repo on a new computer: create one at https://github.com/settings/tokens (scope `repo`) and paste it when Git asks for the password |

---

## PART A – Get ready (do this BEFORE you start recording)

**1.** Open **Windows PowerShell** and start WSL:
```
wsl
```
**2.** Log in to Azure:
```
az login --use-device-code
```
**3.** In your Windows browser open https://login.microsoft.com/device , type the code shown in the terminal, sign in and approve. Wait until the terminal prints JSON and returns to the `$` prompt. (Do not press Ctrl+C.)

**4.** Confirm the subscription is `Robinson_Subscription` and `IsDefault` is True:
```
az account show --output table
```
**5.** Go to the project folder (this finds it automatically):
```
cd "$(dirname "$(find /mnt/c/Users/robin -maxdepth 9 -type d -name project-8935 2>/dev/null | head -n1)")/project-8935"
```
*(Only if you are on a NEW computer and the folder does not exist: run `git clone https://github.com/RobinsonAlzate/Automation-Project-Robinson.git`, then `cd Automation-Project-Robinson/project-8935`. Username = `RobinsonAlzate`, password = your GitHub token.)*

**6.** Check you are in the right folder. You must see `main.tf`, `providers.tf`, `backend.tf`, `outputs.tf`, `terraform.tfvars`:
```
ls
```
**7.** Load the remote backend key (needed in every new terminal):
```
export ARM_ACCESS_KEY=$(az storage account keys list --resource-group rg-tfstate-8935 --account-name tfstate8935ccgc5502 --query '[0].value' -o tsv | tr -d '\r\n')
```
**8.** Check the key. It must print **88**:
```
echo -n "$ARM_ACCESS_KEY" | wc -c
```
*(If it does not print 88, the backend does not exist. Go to the main project folder with `cd ..` and run `bash scripts/backend-setup.sh`, then repeat steps 5 to 8.)*

---

## PART B – Deploy and RECORD

**9.** ▶ **START THE SCREEN RECORDING NOW**, then run these commands one by one:
```
whoami ; hostname ; date
```
**10.**
```
terraform init
```
**11.**
```
terraform validate
```
**12.** Deploy everything, with no questions asked (takes about 15–20 minutes):
```
terraform apply --auto-approve
```
**13.** Must show exactly **48** lines:
```
terraform state list | nl
```
**14.**
```
terraform output
```
**15.** ■ **STOP THE RECORDING** and upload the video to Blackboard → **Terraform Project**.

---

## PART C – Remove everything after the evaluation (saves money)

**16.** Destroy all the infrastructure (the code and the backend stay safe). Takes about 10–15 minutes:
```
terraform destroy --auto-approve
```
**17.** Check it is gone. It must print `false`:
```
az group exists --name 8935-RG
```
**18.** (Optional) Also check the state is empty. It must print nothing:
```
terraform state list
```

---

## If something goes wrong
| Problem | Fix |
|---|---|
| `illegal base64 data` or backend error on `terraform init` | Repeat steps 7 and 8 |
| `ResourceGroupNotFound` for `rg-tfstate-8935` | Run `bash scripts/backend-setup.sh` from the main project folder (`cd ..`) |
| `SkuNotAvailable`, quota or capacity error | Run `terraform destroy --auto-approve`, then from the main folder `bash scripts/find-working-config.sh` (it tests real deployments and saves a working region/size), then deploy again |
| Errors right after a destroy about resources "not found" / RG deleting | Wait a few minutes until `az group exists --name 8935-RG` prints `false`, then run apply again |
| `Error acquiring the state lock` | `terraform force-unlock <LOCK-ID>` (use the ID it shows) |
| Login expired | Repeat step 2 |
| The terminal shows a `>` prompt and does nothing | A quote or backtick was copied by mistake. Press Ctrl+C and paste the command again |

## Notes for the instructor (errors found and fixes applied)
- **Load balancer:** Standard SKU is used because Azure no longer allows creating Basic load balancers (the architecture diagram also shows Standard).
- **Linux VMs:** they are in availability **zones** 1/2/3 as the module text requires. Azure does not allow a VM to be in both a zone and an availability set; the Windows VM uses an availability set.
- **Linux OS:** Ubuntu 22.04 LTS is used instead of CentOS 8.2 because the Azure Monitor Linux Agent extension (v1.45) fails on CentOS 8 with `Unsupported operating system: centos 8`.
- **Region / size:** Canada Central and Central India refused the VM sizes (`SkuNotAvailable` / quota 0 for the B-series family). `scripts/find-working-config.sh` tested real deployments and selected Central US with `Standard_E2bds_v5`.
- **Recovery Services vault:** named `rsv-8935` because Azure requires vault names to start with a letter.
- **Backend key:** `ARM_ACCESS_KEY` is exported manually because the Azure CLI key lookup returned a malformed key in WSL.
