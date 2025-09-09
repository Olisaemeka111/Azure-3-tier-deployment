# Azure 3-Tier Infrastructure - Cost Analysis

## Overview
This document provides comprehensive cost analysis tools and methodologies for tracking the monthly costs of your Azure 3-tier infrastructure.

## Cost Analysis Tools

### 1. Python Cost Analysis Script (`cost_analysis.py`)
A comprehensive Python script that provides detailed cost analysis using Azure APIs.

**Features:**
- Real-time cost data from Azure Consumption API
- Cost breakdown by resource type and individual resources
- Cost optimization recommendations
- Visual cost breakdown charts
- CSV export functionality
- Estimated costs when real data is unavailable

**Usage:**
```bash
# Install dependencies
pip install -r requirements.txt

# Run analysis
python cost_analysis.py --subscription-id YOUR_SUBSCRIPTION_ID --chart --csv
```

### 2. Shell Script (`cost_analysis.sh`)
An automated script that runs multiple cost analysis methods.

**Features:**
- Runs Python cost analysis
- Integrates with Infracost for Terraform cost estimation
- Uses Azure CLI for direct billing data
- Generates comprehensive summary reports
- Creates visual charts and CSV exports

**Usage:**
```bash
# Make executable and run
chmod +x cost_analysis.sh
./cost_analysis.sh
```

### 3. Infracost Integration
Terraform-based cost estimation using Infracost.

**Installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
```

**Usage:**
```bash
# Generate cost breakdown
infracost breakdown --path .

# Generate cost diff (if terraform plan exists)
infracost diff --path .
```

## Current Infrastructure Cost Estimates

Based on the deployed resources, here are the estimated monthly costs:

| Resource Type | Resource Name | Estimated Monthly Cost |
|---------------|---------------|----------------------|
| **Virtual Machines** | | |
| | azure-3tier-ad (Windows Server 2022) | $30.40 |
| | az3t-sql-0 (Windows + SQL Server) | $30.40 |
| | az3t-sql-1 (Windows + SQL Server) | $30.40 |
| **Load Balancers** | | |
| | azure-3tier-biz-lb (Internal) | $18.26 |
| | azure-3tier-db-lb (Internal) | $18.26 |
| **Application Gateway** | | |
| | azure-3tier-appgw (Standard v2) | $195.00 |
| **Azure Bastion** | | |
| | azure-3tier-bastion | $144.00 |
| **Traffic Manager** | | |
| | azure-3tier-tm-ypggv | $1.50 |
| **Public IPs** | | |
| | azure-3tier-appgw-pip (Static) | $3.65 |
| | azure-3tier-bastion-pip (Static) | $3.65 |
| **Storage** | | |
| | OS Disks (3x Standard SSD) | $12.00 |
| **Total Estimated Monthly Cost** | | **$487.52** |

## Cost Breakdown by Category

- **Compute (VMs)**: $91.20 (18.7%)
- **Application Gateway**: $195.00 (40.0%)
- **Azure Bastion**: $144.00 (29.5%)
- **Load Balancers**: $36.52 (7.5%)
- **Storage**: $12.00 (2.5%)
- **Networking**: $8.80 (1.8%)

## Cost Optimization Recommendations

### High-Impact Optimizations

1. **Application Gateway Optimization** (Potential Savings: ~$100/month)
   - Consider Basic SKU if WAF features are not required
   - Current: Standard v2 ($195/month)
   - Alternative: Basic SKU (~$95/month)

2. **Azure Bastion Optimization** (Potential Savings: ~$50/month)
   - Implement auto-shutdown during non-business hours
   - Use only during business hours (8 AM - 6 PM)
   - Current: 24/7 ($144/month)
   - Optimized: Business hours only (~$94/month)

3. **VM Auto-Shutdown** (Potential Savings: ~$45/month)
   - Enable auto-shutdown for VMs during non-business hours
   - SQL VMs: $30.40 × 2 × 0.5 = $30.40 savings
   - AD VM: $30.40 × 0.5 = $15.20 savings

### Medium-Impact Optimizations

4. **Reserved Instances** (Potential Savings: ~$20-30/month)
   - Consider 1-year Reserved Instances for SQL VMs
   - Requires 24/7 operation commitment
   - Typical savings: 20-30% on compute costs

5. **Storage Optimization** (Potential Savings: ~$5-8/month)
   - Review storage types for non-critical data
   - Implement lifecycle policies for backup storage
   - Consider Standard HDD for archive data

### Low-Impact Optimizations

6. **Traffic Manager** (Potential Savings: ~$1.50/month)
   - Consider removing if global load balancing not needed
   - Use Application Gateway alone for load balancing

## Monitoring and Alerting

### Azure Cost Management Setup

1. **Cost Alerts**
   ```bash
   # Set up budget alert
   az consumption budget create \
     --budget-name "3tier-infrastructure-budget" \
     --amount 500 \
     --resource-group azure-3tier-rg-ypggv \
     --time-grain Monthly
   ```

2. **Cost Analysis Dashboard**
   - Access via Azure Portal → Cost Management + Billing
   - Set up custom views for resource group costs
   - Configure daily/weekly cost reports

### Automated Monitoring

1. **Scheduled Cost Analysis**
   ```bash
   # Add to crontab for weekly cost analysis
   0 9 * * 1 /path/to/cost_analysis.sh
   ```

2. **Cost Threshold Alerts**
   - Set up alerts at 80% and 100% of budget
   - Configure email notifications
   - Implement auto-shutdown triggers

## Cost Tracking Best Practices

### 1. Resource Tagging
Ensure all resources are properly tagged for cost allocation:
```bash
# Tag resources for cost tracking
az resource tag --tags Environment=Production CostCenter=IT Department=Engineering --ids /subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/azure-3tier-rg-ypggv
```

### 2. Regular Cost Reviews
- **Weekly**: Review cost trends and anomalies
- **Monthly**: Full cost analysis and optimization review
- **Quarterly**: Strategic cost planning and budget adjustments

### 3. Cost Allocation
- Implement chargeback models for different departments
- Use Azure Cost Management for detailed cost allocation
- Set up cost centers and profit centers

## Files Generated by Cost Analysis

When you run the cost analysis scripts, the following files will be generated:

- `cost_report_YYYYMMDD_HHMMSS.txt`: Detailed cost analysis report
- `cost_breakdown.png`: Visual cost breakdown chart
- `cost_analysis.csv`: Cost data in CSV format
- `infracost_breakdown.json`: Infracost cost estimates (JSON)
- `infracost_breakdown.txt`: Infracost cost estimates (table)
- `azure_cli_costs.json`: Azure CLI billing data (JSON)
- `azure_cli_costs.txt`: Azure CLI billing data (table)
- `COST_SUMMARY.md`: Comprehensive summary report

## Next Steps

1. **Run Initial Analysis**
   ```bash
   ./cost_analysis.sh
   ```

2. **Review Generated Reports**
   - Analyze cost breakdown
   - Identify optimization opportunities
   - Plan implementation timeline

3. **Implement Optimizations**
   - Start with high-impact, low-risk optimizations
   - Monitor cost changes
   - Adjust based on results

4. **Set Up Monitoring**
   - Configure cost alerts
   - Schedule regular analysis
   - Implement automated reporting

5. **Continuous Improvement**
   - Regular cost reviews
   - Update optimization strategies
   - Track ROI of optimizations

---

*This cost analysis framework provides comprehensive tools for tracking, analyzing, and optimizing your Azure 3-tier infrastructure costs.*
