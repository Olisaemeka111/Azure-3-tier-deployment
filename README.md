# Azure 3-Tier Architecture with Terraform

This project provisions an Azure environment similar to the provided diagram, now hardened with Bastion and WAF:

- Traffic Manager in front of an Application Gateway WAF v2 (Public)
- Web tier VM Scale Set behind App Gateway (HTTP/HTTPS)
- Internal Load Balancer for Business tier (TCP/8080)
- Internal Load Balancer for Database tier (TCP/1433) with Windows SQL Server VMs
- Virtual Network with subnets: web, business, db, management, appgateway, AzureBastionSubnet
- NSGs tightened: Web allows 80/443 only from App Gateway; Management allows 22/3389 from `admin_source_ip`; Business intra‑VNet; DB 1433 from Business only
- Azure Bastion instead of public jumpbox for SSH/RDP

## Prerequisites
- Terraform >= 1.5
- Azure CLI authenticated: `az login`
- SSH public key present at `~/.ssh/id_rsa.pub` or provide `admin_ssh_key` variable

## Usage
```bash
terraform init
terraform apply -auto-approve
```

This repo includes a `terraform.tfvars` with sane defaults. Edit it as needed (e.g., set `admin_source_ip = "YOUR_IP/32"`, `admin_password`, `domain_name`, and `dsrm_password`; add `subnet_appgw_cidr` and `subnet_bastion_cidr`) and re-apply.

### Variables of interest
- `name_prefix`, `location`, CIDRs for VNet and subnets
- `admin_username`, `admin_password` (Windows), `admin_ssh_key` (Linux)
- `web_count`, `biz_count`, `sql_vm_count`; `vm_size_*`
- `domain_name` and `dsrm_password` for AD DS; SQL VMs auto-join the domain

### What gets created
- Web: Ubuntu VMSS with NGINX behind Application Gateway WAF v2
- Business: Ubuntu VMSS behind internal LB on TCP 8080
- Database: Windows Server 2022 + SQL Server 2019 Standard VMs behind internal LB on 1433
- AD DS: Windows Server 2022 promoted to a new forest defined by `domain_name`
- NSGs: Web (80/443), Management (22/3389 from `admin_source_ip`), Business (intra-VNet), DB (1433 only from Business subnet)

## Outputs
- `resource_group_name` – Resource Group created
- `traffic_manager_fqdn` – DNS name to reach the App Gateway
- App Gateway public IP is shown in the Azure Portal (or add an output if needed)

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
