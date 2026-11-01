# CCGC 5502 – Automation with Terraform (Azure)

**Student:** Robinson Alzatte  
**Humber ID (last 4 digits used in all names):** 8935  
**GitHub repository:** https://github.com/RobinsonAlzate/Automation-Project-Robinson

## About this project
For this project I wrote Terraform code that builds a complete Azure environment with a single command, `terraform apply --auto-approve`.
Everything is deployed in the **Central US** region and is split into 8 child modules plus one root module (`project-8935`):

| Module | What it creates |
|---|---|
| `rgroup-8935` | Resource group `8935-RG` |
| `network-8935` | Virtual network `8935-VNET`, subnet `8935-SUBNET`, and a network security group with inbound rules for ports 22, 3389, 5985 and 80 |
| `common-8935` | Log Analytics workspace, Recovery Services vault and a standard LRS storage account (used for VM boot diagnostics) |
| `vmlinux-8935` | 3 Linux VMs, one in each availability zone, built with `for_each`. Each has a public IP, a unique DNS label, the Network Watcher and Azure Monitor extensions, and a `remote-exec` null provisioner that prints its hostname |
| `vmwindows-8935` | 1 Windows Server 2022 VM, built with `count`, placed in an availability set, with the Antimalware extension |
| `datadisk-8935` | One 10 GB data disk attached to each of the 4 VMs |
| `loadbalancer-8935` | Public Standard load balancer with the 3 Linux VMs in the backend pool |
| `database-8935` | Azure Database for PostgreSQL flexible server |

The Terraform state is kept in a remote backend (an Azure storage account that is never destroyed), all resources carry the required tags, and a correct deployment creates exactly **48 resources**.

## Key information
| Item | Value |
|---|---|
| Azure subscription | `Robinson_Subscription` (ID `8c8941f9-9a8e-4c24-a1f8-60fc998da3c3`) |
| Region / VM size | `centralus` / `Standard_E2bds_v5` |
| Linux OS | Ubuntu 22.04 LTS (reason explained in the notes below) |
| VM admin user / password | `azureadmin` / `Ccgc5502#Terraform2026` |
| PostgreSQL admin user / password | `pgadmin` / `Ccgc5502#Postgres2026` |
| Remote backend | resource group `rg-tfstate-8935`, storage account `tfstate8935ccgc5502`, container `tfstate` |
| Tags on every resource | Project = `CCGC 5502 Terraform Project`, Name = `robinson.alzatte`, ExpirationDate = `2027-12-31`, Environment = `Learning` |
| GitHub token | Not stored in the repository (it is a secret). I only need it to clone or push; I create it at https://github.com/settings/tokens with the `repo` scope |

---

## How I deploy the project (step by step)

### Part A – Preparation (before recording)

**1.** I open Windows PowerShell and start WSL:
```
wsl
```
**2.** I log in to Azure with the device code method:
```
az login --use-device-code
```
**3.** In my browser I open https://login.microsoft.com/device , enter the code shown in the terminal, sign in and approve. I wait until the terminal prints JSON and returns to the `$` prompt.

**4.** I confirm the active subscription is `Robinson_Subscription` and that `IsDefault` is True:
```
az account show --output table
```
**5.** I go to the project folder (this command finds it automatically):
```
cd "$(dirname "$(find /mnt/c/Users/robin -maxdepth 9 -type d -name project-8935 2>/dev/null | head -n1)")/project-8935"
```
*I clone the repository instead (username `RobinsonAlzate`, password = my GitHub token):*
```
git clone https://github.com/RobinsonAlzate/Automation-Project-Robinson.git
```
```
cd Automation-Project-Robinson/project-8935
```
**6.** I check that I am in the right folder. I should see `main.tf`, `providers.tf`, `backend.tf`, `outputs.tf` and `terraform.tfvars`:
```
ls
```
**7.** I load the key of the remote backend storage account (this is needed in every new terminal):
```
export ARM_ACCESS_KEY=$(az storage account keys list --resource-group rg-tfstate-8935 --account-name tfstate8935ccgc5502 --query '[0].value' -o tsv | tr -d '\r\n')
```
**8.** I check the key. It must print **88**:
```
echo -n "$ARM_ACCESS_KEY" | wc -c
```
*(If it does not print 88, the backend does not exist. I go up one folder with `cd ..`, run `bash scripts/backend-setup.sh`, and repeat steps 5 to 8.)*

### Part B – Deployment (this is what I record)

**9.** I start the screen recording and run the first command:
```
whoami ; hostname ; date
```
**10.** I initialize Terraform (plugins, modules and the remote backend):
```
terraform init
```
**11.** I validate the configuration:
```
terraform validate
```
**12.** I deploy the whole infrastructure without any prompts (about 15 to 20 minutes):
```
terraform apply --auto-approve
```
**13.** I list the resources in the state. The list must show exactly **48** lines:
```
terraform state list | nl
```
**14.** I display all the outputs (hostnames, FQDNs, private and public IPs, virtual network, subnet, storage account, Log Analytics workspace, Recovery Services vault, load balancer and database):
```
terraform output
```
**15.** I stop the recording and upload the video to Blackboard under **Terraform Project**.

### Part C – Cleanup after the evaluation

**16.** I destroy all the infrastructure to avoid costs (the code and the remote backend stay safe; takes about 10 to 15 minutes):
```
terraform destroy --auto-approve
```
**17.** I confirm the resource group is gone. It must print `false`:
```
az group exists --name 8935-RG
```
**18.** I confirm the state is empty. It must print nothing:
```
terraform state list
```

---

## Problems I ran into and how I fixed them
| Problem | Fix |
|---|---|
| `illegal base64 data` or a backend error on `terraform init` | I export the backend key again (steps 7 and 8) and re-run `terraform init` |
| `ResourceGroupNotFound` for `rg-tfstate-8935` | I run `bash scripts/backend-setup.sh` from the main project folder to create the backend |
| `SkuNotAvailable`, quota or capacity errors on the VMs or database | I destroy the deployment and run `bash scripts/find-working-config.sh` from the main folder. It tests real deployments and saves a working region, VM size and database size in `terraform.tfvars` |
| "Inconsistent result after apply" right after a destroy | The old resource group was still being deleted. I wait until `az group exists --name 8935-RG` prints `false` and apply again |
| `Error acquiring the state lock` | `terraform force-unlock <LOCK-ID>` with the ID shown in the error |
| `Module not installed` | The terminal is pointing to an old copy of the folder. I run `cd ~`, repeat step 5, and run `terraform init` |
| Azure login expired | I repeat step 2 |
| The terminal shows a `>` prompt and does nothing | A quote or backtick was copied by mistake. I press Ctrl+C and paste the command again |

## Notes for the instructor (errors found and fixes applied)
- **Load balancer:** I used the Standard SKU because Azure no longer allows creating Basic load balancers; the architecture diagram also shows a Standard load balancer.
- **Linux VMs:** they are placed in availability zones 1, 2 and 3, as the module description requires. Azure does not allow a VM to be in both a zone and an availability set, so only the Windows VM uses an availability set.
- **Linux operating system:** I used Ubuntu 22.04 LTS instead of CentOS 8.2. The required Azure Monitor Linux Agent extension (version 1.45) failed on CentOS 8 with the error `Unsupported operating system: centos 8`.
- **Region and VM size:** Canada Central and Central India refused the VM sizes (`SkuNotAvailable` and zero quota for the B-series family on my subscription). I wrote `scripts/find-working-config.sh`, which tests real deployments, and it selected Central US with `Standard_E2bds_v5`.
- **Recovery Services vault:** it is named `rsv-8935` because Azure requires vault names to start with a letter.
- **Database:** the PostgreSQL flexible server uses the `B_Standard_B1ms` size, which was the one offered in Central US for my subscription.
- **Backend key:** I export `ARM_ACCESS_KEY` manually because the key lookup done by the Azure CLI returned a malformed key inside WSL.
