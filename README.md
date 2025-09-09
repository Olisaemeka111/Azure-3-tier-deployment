# Azure 3-Tier Architecture with Terraform

This project provisions an Azure environment similar to the provided diagram:

- Traffic Manager in front of a public Load Balancer for the Web tier
- Web tier VM Scale Set behind Public LB (HTTP/80)
- Internal Load Balancer for Business tier (TCP/8080)
- Internal Load Balancer for Database tier (TCP/1433) with Windows SQL Server VMs
- Virtual Network with subnets: web, business, db, management
- NSGs for web exposure, management SSH, and internal communication
- Management subnet with a Jumpbox and a Windows Server AD DS domain controller

## Prerequisites
- Terraform >= 1.5
- Azure CLI authenticated: `az login`
- SSH public key present at `~/.ssh/id_rsa.pub` or provide `admin_ssh_key` variable

## Usage
```bash
terraform init
terraform apply -auto-approve
```

This repo includes a `terraform.tfvars` with sane defaults. Edit it as needed (e.g., set `admin_source_ip = "YOUR_IP/32"`, `admin_password`, `domain_name`, and `dsrm_password`) and re-apply.

### Variables of interest
- `name_prefix`, `location`, CIDRs for VNet and subnets
- `admin_username`, `admin_password` (Windows), `admin_ssh_key` (Linux)
- `web_count`, `biz_count`, `sql_vm_count`; `vm_size_*`
- `domain_name` and `dsrm_password` for AD DS; SQL VMs auto-join the domain

### What gets created
- Web: Ubuntu VMSS with NGINX behind Public LB
- Business: Ubuntu VMSS behind internal LB on TCP 8080
- Database: Windows Server 2022 + SQL Server 2019 Standard VMs behind internal LB on 1433
- AD DS: Windows Server 2022 promoted to a new forest defined by `domain_name`
- NSGs: Web (80/443), Management (22/3389 from `admin_source_ip`), Business (intra-VNet), DB (1433 only from Business subnet)

## Outputs
- `resource_group_name` – Resource Group created
- `web_lb_public_ip` – Public IP of Web Load Balancer
- `traffic_manager_fqdn` – DNS name to reach the Web tier via Traffic Manager
- `jumpbox_public_ip` – Public IP for SSH to the jumpbox

## Notes
- The DB tier uses Linux VMs for demo purposes; replace with Azure SQL or Windows if needed.
- For production, tighten NSG rules, add availability zones, diagnostics, and backups. Consider using Azure SQL Managed Instance or SQL Always On, and harden AD DS deployment (GPOs, multiple DCs, secure passwords and secrets management).

## Push to GitHub
Run the following inside this folder to push to a new repo (replace the URL):
```bash
git init
git add .
git commit -m "feat: Azure 3-tier with Web/Biz/SQL, AD DS, TM"
git branch -M main
git remote add origin https://github.com/<YOUR_USER>/<YOUR_REPO>.git
git push -u origin main
```

# Azure-3-tier-deployment
