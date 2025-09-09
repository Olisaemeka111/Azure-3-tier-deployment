#!/bin/bash
# Azure 3-Tier Infrastructure Cost Analysis Script
# This script provides multiple ways to analyze infrastructure costs

set -e

# Configuration
SUBSCRIPTION_ID="9b8b49a9-222a-4179-b2a7-20fd90dd0264"
RESOURCE_GROUP="azure-3tier-rg-ypggv"
OUTPUT_DIR="./cost_reports"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}Azure 3-Tier Infrastructure Cost Analysis${NC}"
echo "=============================================="
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Resource Group: $RESOURCE_GROUP"
echo "Output Directory: $OUTPUT_DIR"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Python dependencies
install_python_deps() {
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    if command_exists pip3; then
        pip3 install -r requirements.txt
    elif command_exists pip; then
        pip install -r requirements.txt
    else
        echo -e "${RED}Error: pip not found. Please install Python and pip.${NC}"
        exit 1
    fi
}

# Function to run Python cost analysis
run_python_analysis() {
    echo -e "${GREEN}Running Python cost analysis...${NC}"
    python3 cost_analysis.py \
        --subscription-id "$SUBSCRIPTION_ID" \
        --resource-group "$RESOURCE_GROUP" \
        --output-dir "$OUTPUT_DIR" \
        --all
}

# Function to run Infracost analysis
run_infracost_analysis() {
    if command_exists infracost; then
        echo -e "${GREEN}Running Infracost analysis...${NC}"
        
        # Generate cost estimate
        infracost breakdown --path . --format json > "$OUTPUT_DIR/infracost_breakdown.json"
        infracost breakdown --path . --format table > "$OUTPUT_DIR/infracost_breakdown.txt"
        
        # Generate diff if terraform plan exists
        if [ -f "terraform.tfplan" ]; then
            infracost diff --path . --format json > "$OUTPUT_DIR/infracost_diff.json"
            infracost diff --path . --format table > "$OUTPUT_DIR/infracost_diff.txt"
        fi
        
        echo -e "${GREEN}Infracost analysis completed.${NC}"
    else
        echo -e "${YELLOW}Infracost not installed. Skipping Infracost analysis.${NC}"
        echo "To install Infracost:"
        echo "  curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh"
    fi
}

# Function to run Azure CLI cost analysis
run_azure_cli_analysis() {
    if command_exists az; then
        echo -e "${GREEN}Running Azure CLI cost analysis...${NC}"
        
        # Get current month costs (using date range instead of billing period)
        START_DATE=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d)
        END_DATE=$(date +%Y-%m-%d)
        
        az consumption usage list \
            --start-date "$START_DATE" \
            --end-date "$END_DATE" \
            --output table > "$OUTPUT_DIR/azure_cli_costs.txt"
        
        # Get resource costs
        az consumption usage list \
            --start-date "$START_DATE" \
            --end-date "$END_DATE" \
            --output json > "$OUTPUT_DIR/azure_cli_costs.json"
        
        echo -e "${GREEN}Azure CLI cost analysis completed.${NC}"
    else
        echo -e "${YELLOW}Azure CLI not installed. Skipping Azure CLI analysis.${NC}"
    fi
}

# Function to generate summary report
generate_summary_report() {
    echo -e "${GREEN}Generating summary report...${NC}"
    
    cat > "$OUTPUT_DIR/COST_SUMMARY.md" << EOF
# Azure 3-Tier Infrastructure - Cost Analysis Summary

Generated: $(date)
Subscription ID: $SUBSCRIPTION_ID
Resource Group: $RESOURCE_GROUP

## Analysis Methods Used

1. **Python Cost Analysis**: Comprehensive cost breakdown with optimization recommendations
2. **Infracost Analysis**: Terraform-based cost estimation
3. **Azure CLI Analysis**: Direct Azure billing data

## Files Generated

- \`cost_report_*.txt\`: Detailed cost analysis report
- \`cost_breakdown.png\`: Visual cost breakdown chart
- \`cost_analysis.csv\`: Cost data in CSV format
- \`infracost_breakdown.*\`: Infracost cost estimates
- \`azure_cli_costs.*\`: Azure CLI billing data

## Cost Optimization Recommendations

1. **Application Gateway**: Consider Basic SKU if WAF not needed (~$100/month savings)
2. **Azure Bastion**: Implement auto-shutdown or use only during business hours (~$50/month savings)
3. **Virtual Machines**: Enable auto-shutdown for non-business hours (~$15-20/month per VM)
4. **Reserved Instances**: Consider for SQL VMs if running 24/7
5. **Storage Optimization**: Review storage types and implement lifecycle policies

## Monitoring and Alerts

- Set up Azure Cost Management alerts
- Implement Azure Advisor recommendations
- Use Azure Policy for cost controls
- Regular cost reviews (monthly)

## Next Steps

1. Review generated reports
2. Implement cost optimization recommendations
3. Set up monitoring and alerts
4. Schedule regular cost reviews
EOF

    echo -e "${GREEN}Summary report generated: $OUTPUT_DIR/COST_SUMMARY.md${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting cost analysis...${NC}"
    
    # Check if Python script exists
    if [ ! -f "cost_analysis.py" ]; then
        echo -e "${RED}Error: cost_analysis.py not found.${NC}"
        exit 1
    fi
    
    # Install dependencies
    install_python_deps
    
    # Run analyses
    run_python_analysis
    run_infracost_analysis
    run_azure_cli_analysis
    
    # Generate summary
    generate_summary_report
    
    echo ""
    echo -e "${GREEN}Cost analysis completed successfully!${NC}"
    echo -e "${BLUE}Reports saved in: $OUTPUT_DIR${NC}"
    echo ""
    echo "Generated files:"
    ls -la "$OUTPUT_DIR"
}

# Run main function
main "$@"
