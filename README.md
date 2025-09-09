# Azure 3-Tier Architecture with Terraform

A comprehensive Infrastructure as Code (IaC) solution for deploying a secure, scalable 3-tier architecture on Microsoft Azure using Terraform. This project implements enterprise-grade security practices with Azure Bastion, Application Gateway WAF v2, and hardened Network Security Groups.

## 🏗️ Architecture Overview

This project provisions a complete Azure environment with the following components:

### **Core Infrastructure**
- **Traffic Manager** - DNS-based load balancing and failover
- **Application Gateway WAF v2** - Web Application Firewall with SSL termination
- **Azure Bastion** - Secure RDP/SSH connectivity over TLS
- **Virtual Network** - Isolated network with 6 subnets for proper segmentation

### **Application Tiers**
- **Web Tier** - Ubuntu VM Scale Set with NGINX behind Application Gateway
- **Business Tier** - Ubuntu VM Scale Set behind internal load balancer
- **Database Tier** - Windows SQL Server 2019 VMs with internal load balancing
- **Management Tier** - Windows Server 2022 with Active Directory Domain Services

### **Security Features**
- **Network Security Groups** - Tightened rules for each tier
- **Azure Bastion** - No direct RDP/SSH exposure to internet
- **WAF Protection** - Application-level security at the gateway
- **Subnet Isolation** - Proper network segmentation

## 📋 Prerequisites

- **Terraform** >= 1.5
- **Azure CLI** authenticated: `az login`
- **Azure Subscription** with appropriate permissions
- **SSH Public Key** at `~/.ssh/id_rsa.pub` or provide `admin_ssh_key` variable

## 🚀 Quick Start

### 1. Clone and Initialize
```bash
git clone https://github.com/Olisaemeka111/Azure-3-tier-deployment.git
cd Azure-3-tier-deployment
terraform init
```

### 2. Configure Variables
Edit `terraform.tfvars` with your specific values:
```hcl
# Required: Set your admin IP for management access
admin_source_ip = "YOUR_PUBLIC_IP/32"

# Required: Set secure passwords
admin_password = "YourSecurePassword123!"
dsrm_password = "YourDSRMPassword123!"

# Optional: Customize domain and resources
domain_name = "yourdomain.com"
sql_vm_count = 2
web_count = 2
biz_count = 2
```

### 3. Deploy Infrastructure
```bash
terraform plan
terraform apply
```

### 4. Access Your Infrastructure
- **Web Application**: `https://your-traffic-manager-fqdn.trafficmanager.net`
- **Management**: Connect via Azure Bastion in the Azure Portal
- **AD Domain**: `yourdomain.com` (as configured)

## 📁 Project Structure

```
├── main.tf                 # Core resources and VM configurations
├── network.tf              # Virtual network and subnet definitions
├── security.tf             # Network Security Groups and rules
├── loadbalancers.tf        # Load balancers and Application Gateway
├── variables.tf            # Input variable definitions
├── outputs.tf              # Output values
├── versions.tf             # Provider version constraints
├── terraform.tfvars        # Variable values (customize this)
├── .gitignore              # Git ignore rules
├── README.md               # This file
├── ARCHITECTURE.md         # Detailed architecture documentation
├── RESOURCES.md            # Complete resource inventory
├── COST_ANALYSIS.md        # Cost analysis and optimization
├── COST_OUTPUT_FORMATS.md  # Cost reporting formats
├── cost_analysis.py        # Python cost analysis script
├── cost_analysis.sh        # Automated cost analysis script
├── requirements.txt        # Python dependencies
├── diagrams/               # Architecture diagrams
│   ├── architecture.png    # Static architecture diagram
│   ├── architecture.svg    # Vector architecture diagram
│   └── architecture.mmd    # Mermaid source
└── cost_reports/           # Generated cost reports
    ├── cost_breakdown.png  # Cost pie chart
    ├── cost_bar_chart.png  # Cost bar chart
    ├── detailed_cost_analysis.xlsx  # Excel cost report
    └── cost_analysis.csv   # CSV cost data
```

## 🔧 Configuration Options

### **Key Variables**
- `name_prefix` - Prefix for all resource names
- `location` - Azure region for deployment
- `admin_source_ip` - Your public IP for management access
- `domain_name` - Active Directory domain name
- `sql_vm_count` - Number of SQL Server VMs (default: 2)
- `web_count` - Number of web tier VMs (default: 2)
- `biz_count` - Number of business tier VMs (default: 2)

### **VM Sizes**
- `vm_size_web` - Web tier VM size (default: Standard_B2s)
- `vm_size_biz` - Business tier VM size (default: Standard_B2s)
- `vm_size_sql` - SQL Server VM size (default: Standard_B2s)
- `vm_size_ad` - AD DS VM size (default: Standard_B1ms)

### **Network Configuration**
- `vnet_cidr` - Virtual network CIDR (default: 10.0.0.0/16)
- `subnet_web_cidr` - Web subnet (default: 10.0.1.0/24)
- `subnet_biz_cidr` - Business subnet (default: 10.0.2.0/24)
- `subnet_db_cidr` - Database subnet (default: 10.0.3.0/24)
- `subnet_mgmt_cidr` - Management subnet (default: 10.0.10.0/24)

## 🏢 What Gets Created

### **Compute Resources**
- **Web Tier**: Ubuntu 20.04 VM Scale Set with NGINX
- **Business Tier**: Ubuntu 20.04 VM Scale Set for application logic
- **Database Tier**: Windows Server 2022 + SQL Server 2019 Standard VMs
- **Management**: Windows Server 2022 with Active Directory Domain Services

### **Networking**
- **Virtual Network**: 10.0.0.0/16 with 6 subnets
- **Public IPs**: Application Gateway and Azure Bastion
- **Load Balancers**: Internal load balancers for business and database tiers
- **Application Gateway**: WAF v2 with HTTP/HTTPS routing

### **Security**
- **Network Security Groups**: Tier-specific security rules
- **Azure Bastion**: Secure management access
- **WAF Rules**: Application-level protection

## 📊 Cost Analysis

This project includes comprehensive cost analysis tools:

### **Automated Cost Analysis**
```bash
# Run complete cost analysis
./cost_analysis.sh

# Generate specific reports
python3 cost_analysis.py --bar-chart
python3 cost_analysis.py --excel
python3 cost_analysis.py --all
```

### **Cost Reports Generated**
- **Pie Chart**: Visual cost breakdown by resource type
- **Bar Chart**: Cost comparison across resource categories
- **Excel Report**: Detailed multi-sheet analysis with optimization recommendations
- **CSV Export**: Raw cost data for further analysis

### **Estimated Monthly Costs**
- **Total**: ~$487.52/month (based on current Azure pricing)
- **Breakdown**: VMs (60%), Storage (25%), Networking (15%)

## 🔒 Security Features

### **Network Security**
- **Tier Isolation**: Each tier in separate subnets
- **NSG Rules**: Restrictive inbound/outbound rules
- **No Direct Internet Access**: Database and business tiers isolated
- **Azure Bastion**: Secure management without public IPs

### **Application Security**
- **WAF Protection**: OWASP Top 10 protection
- **SSL/TLS**: HTTPS termination at Application Gateway
- **Domain Security**: Active Directory with secure authentication

### **Access Control**
- **RBAC**: Role-based access control
- **MFA Support**: Multi-factor authentication ready
- **Audit Logging**: Azure Monitor and Log Analytics ready

## 🛠️ Management and Operations

### **Accessing Resources**
1. **Web Application**: Via Traffic Manager FQDN
2. **Management VMs**: Through Azure Bastion in Azure Portal
3. **Database**: Via internal load balancer from business tier
4. **Active Directory**: Domain-joined VMs automatically

### **Monitoring and Logging**
- **Azure Monitor**: Built-in monitoring for all resources
- **Log Analytics**: Centralized logging (can be added)
- **Application Insights**: Application performance monitoring (can be added)

### **Backup and Recovery**
- **VM Backups**: Azure Backup can be enabled
- **Database Backups**: SQL Server backup strategies
- **Infrastructure**: Terraform state management

## 🔄 Scaling and Modifications

### **Horizontal Scaling**
```hcl
# Increase VM counts in terraform.tfvars
web_count = 4
biz_count = 4
sql_vm_count = 3
```

### **Vertical Scaling**
```hcl
# Upgrade VM sizes
vm_size_web = "Standard_D2s_v5"
vm_size_biz = "Standard_D2s_v5"
vm_size_sql = "Standard_D4s_v5"
```

### **Adding Resources**
- **Additional Subnets**: Modify `network.tf`
- **New VMs**: Add to `main.tf`
- **Security Rules**: Update `security.tf`

## 🧹 Cleanup

### **Destroy Infrastructure**
```bash
# Remove all resources
terraform destroy

# Verify cleanup
terraform state list
```

### **Cost Verification**
- Check Azure Cost Management
- Verify no resources remain in the resource group
- Confirm all public IPs are released

## 📚 Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed architecture diagrams and explanations
- **[RESOURCES.md](RESOURCES.md)** - Complete resource inventory and specifications
- **[COST_ANALYSIS.md](COST_ANALYSIS.md)** - Cost analysis methodology and optimization
- **[COST_OUTPUT_FORMATS.md](COST_OUTPUT_FORMATS.md)** - Cost reporting formats and usage

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Issues**: Report bugs and request features via GitHub Issues
- **Documentation**: Check the documentation files in the repository
- **Azure Support**: For Azure-specific issues, contact Azure Support

## 🏆 Best Practices Implemented

- **Infrastructure as Code**: Complete Terraform automation
- **Security by Design**: Defense in depth with multiple security layers
- **Cost Optimization**: Right-sized resources with cost analysis tools
- **Documentation**: Comprehensive documentation and diagrams
- **Modularity**: Separated concerns across multiple Terraform files
- **Version Control**: Git-based version control with proper .gitignore
- **Monitoring Ready**: Built-in monitoring and logging capabilities

---

**⚠️ Important Notes:**
- This is a demonstration environment. For production use, implement additional security measures, monitoring, and backup strategies.
- Always review and customize the configuration before deployment.
- Regularly update Terraform and Azure provider versions.
- Monitor costs and optimize resources based on actual usage patterns.
