#!/usr/bin/env python3
"""
Azure 3-Tier Infrastructure Cost Analysis Script
================================================

This script provides comprehensive cost analysis for the Azure 3-tier infrastructure.
It calculates monthly costs, provides cost breakdowns by resource type, and generates
cost optimization recommendations.

Requirements:
- pip install azure-mgmt-consumption azure-identity requests pandas matplotlib
- Azure CLI configured with appropriate permissions
- Infracost CLI installed (optional, for Terraform cost estimation)

Usage:
    python cost_analysis.py [--subscription-id SUBSCRIPTION_ID] [--resource-group RESOURCE_GROUP]
"""

import argparse
import json
import os
import sys
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import requests
import pandas as pd
import matplotlib.pyplot as plt
from azure.identity import DefaultAzureCredential
from azure.mgmt.consumption import ConsumptionManagementClient
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.network import NetworkManagementClient

class AzureCostAnalyzer:
    def __init__(self, subscription_id: str, resource_group: str = "azure-3tier-rg-ypggv"):
        self.subscription_id = subscription_id
        self.resource_group = resource_group
        self.credential = DefaultAzureCredential()
        
        # Initialize Azure clients
        self.consumption_client = ConsumptionManagementClient(
            self.credential, subscription_id
        )
        self.resource_client = ResourceManagementClient(
            self.credential, subscription_id
        )
        self.compute_client = ComputeManagementClient(
            self.credential, subscription_id
        )
        self.network_client = NetworkManagementClient(
            self.credential, subscription_id
        )
        
        # Cost data storage
        self.cost_data = {}
        self.resource_costs = {}
        
    def get_current_month_costs(self) -> Dict:
        """Get current month's costs for the resource group."""
        try:
            # Get current month's start and end dates
            now = datetime.now()
            start_date = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            end_date = now
            
            # Format dates for Azure API
            start_date_str = start_date.strftime("%Y-%m-%d")
            end_date_str = end_date.strftime("%Y-%m-%d")
            
            print(f"Fetching costs from {start_date_str} to {end_date_str}...")
            
            # Get usage details for the resource group
            usage_details = self.consumption_client.usage_details.list(
                scope=f"/subscriptions/{self.subscription_id}/resourceGroups/{self.resource_group}",
                filter=f"properties/usageStart ge '{start_date_str}' and properties/usageEnd le '{end_date_str}'"
            )
            
            total_cost = 0.0
            resource_breakdown = {}
            
            for usage in usage_details:
                cost = float(usage.cost) if usage.cost else 0.0
                total_cost += cost
                
                resource_name = usage.resource_name or "Unknown"
                resource_type = usage.resource_type or "Unknown"
                
                if resource_type not in resource_breakdown:
                    resource_breakdown[resource_type] = {
                        'total_cost': 0.0,
                        'resources': {}
                    }
                
                resource_breakdown[resource_type]['total_cost'] += cost
                
                if resource_name not in resource_breakdown[resource_type]['resources']:
                    resource_breakdown[resource_type]['resources'][resource_name] = 0.0
                
                resource_breakdown[resource_type]['resources'][resource_name] += cost
            
            return {
                'total_cost': total_cost,
                'period': f"{start_date_str} to {end_date_str}",
                'breakdown': resource_breakdown
            }
            
        except Exception as e:
            print(f"Error fetching current month costs: {e}")
            return self.get_estimated_costs()
    
    def get_estimated_costs(self) -> Dict:
        """Get estimated costs based on resource types and sizes."""
        print("Using estimated costs (actual usage data not available)...")
        
        # Estimated monthly costs based on current resource configuration
        estimated_costs = {
            'total_cost': 0.0,
            'period': 'Estimated Monthly',
            'breakdown': {
                'Microsoft.Compute/virtualMachines': {
                    'total_cost': 0.0,
                    'resources': {}
                },
                'Microsoft.Compute/virtualMachineScaleSets': {
                    'total_cost': 0.0,
                    'resources': {}
                },
                'Microsoft.Network/loadBalancers': {
                    'total_cost': 0.0,
                    'resources': {}
                },
                'Microsoft.Network/applicationGateways': {
                    'total_cost': 0.0,
                    'resources': {}
                },
                'Microsoft.Network/bastionHosts': {
                    'total_cost': 0.0,
                    'resources': {}
                },
                'Microsoft.Network/trafficmanagerprofiles': {
                    'total_cost': 0.0,
                    'resources': {}
                },
                'Microsoft.Network/publicIPAddresses': {
                    'total_cost': 0.0,
                    'resources': {}
                },
                'Microsoft.Storage/storageAccounts': {
                    'total_cost': 0.0,
                    'resources': {}
                }
            }
        }
        
        # Cost estimates based on typical Azure pricing (East US region)
        cost_estimates = {
            # Virtual Machines (Standard_B2s - 2 vCPUs, 4 GB RAM)
            'azure-3tier-ad': 30.40,  # Windows Server 2022
            'az3t-sql-0': 30.40,      # Windows Server 2022 + SQL Server
            'az3t-sql-1': 30.40,      # Windows Server 2022 + SQL Server
            
            # Load Balancers (Standard SKU)
            'azure-3tier-biz-lb': 18.26,  # Internal LB
            'azure-3tier-db-lb': 18.26,   # Internal LB
            
            # Application Gateway (Standard v2)
            'azure-3tier-appgw': 195.00,  # Standard v2 with WAF
            
            # Azure Bastion
            'azure-3tier-bastion': 144.00,  # Standard Bastion
            
            # Traffic Manager
            'azure-3tier-tm-ypggv': 1.50,  # Standard profile
            
            # Public IPs (Static)
            'azure-3tier-appgw-pip': 3.65,   # Static IP
            'azure-3tier-bastion-pip': 3.65, # Static IP
            
            # Storage (OS Disks - Standard SSD)
            'azure-3tier-ad_OsDisk': 4.00,   # 30 GB Standard SSD
            'az3t-sql-0_OsDisk': 4.00,       # 30 GB Standard SSD
            'az3t-sql-1_OsDisk': 4.00,       # 30 GB Standard SSD
        }
        
        # Calculate total estimated cost
        total_estimated = sum(cost_estimates.values())
        estimated_costs['total_cost'] = total_estimated
        
        # Categorize costs by resource type
        for resource_name, cost in cost_estimates.items():
            if 'vm' in resource_name.lower() or 'sql' in resource_name.lower() or 'ad' in resource_name.lower():
                resource_type = 'Microsoft.Compute/virtualMachines'
            elif 'lb' in resource_name.lower():
                resource_type = 'Microsoft.Network/loadBalancers'
            elif 'appgw' in resource_name.lower():
                resource_type = 'Microsoft.Network/applicationGateways'
            elif 'bastion' in resource_name.lower():
                resource_type = 'Microsoft.Network/bastionHosts'
            elif 'tm' in resource_name.lower():
                resource_type = 'Microsoft.Network/trafficmanagerprofiles'
            elif 'pip' in resource_name.lower():
                resource_type = 'Microsoft.Network/publicIPAddresses'
            elif 'disk' in resource_name.lower():
                resource_type = 'Microsoft.Storage/storageAccounts'
            else:
                resource_type = 'Microsoft.Compute/virtualMachines'
            
            estimated_costs['breakdown'][resource_type]['total_cost'] += cost
            estimated_costs['breakdown'][resource_type]['resources'][resource_name] = cost
        
        return estimated_costs
    
    def generate_cost_report(self, cost_data: Dict) -> str:
        """Generate a detailed cost report."""
        report = []
        report.append("=" * 80)
        report.append("AZURE 3-TIER INFRASTRUCTURE - COST ANALYSIS REPORT")
        report.append("=" * 80)
        report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"Subscription ID: {self.subscription_id}")
        report.append(f"Resource Group: {self.resource_group}")
        report.append(f"Period: {cost_data['period']}")
        report.append("")
        
        # Total cost summary
        report.append("COST SUMMARY")
        report.append("-" * 40)
        report.append(f"Total Monthly Cost: ${cost_data['total_cost']:.2f}")
        report.append(f"Daily Average: ${cost_data['total_cost'] / 30:.2f}")
        report.append(f"Hourly Average: ${cost_data['total_cost'] / (30 * 24):.2f}")
        report.append("")
        
        # Cost breakdown by resource type
        report.append("COST BREAKDOWN BY RESOURCE TYPE")
        report.append("-" * 50)
        
        sorted_breakdown = sorted(
            cost_data['breakdown'].items(),
            key=lambda x: x[1]['total_cost'],
            reverse=True
        )
        
        for resource_type, data in sorted_breakdown:
            if data['total_cost'] > 0:
                percentage = (data['total_cost'] / cost_data['total_cost']) * 100
                report.append(f"{resource_type}")
                report.append(f"  Total Cost: ${data['total_cost']:.2f} ({percentage:.1f}%)")
                
                # Individual resources
                for resource_name, cost in data['resources'].items():
                    report.append(f"    - {resource_name}: ${cost:.2f}")
                report.append("")
        
        # Cost optimization recommendations
        report.append("COST OPTIMIZATION RECOMMENDATIONS")
        report.append("-" * 50)
        
        recommendations = self.get_cost_optimization_recommendations(cost_data)
        for i, rec in enumerate(recommendations, 1):
            report.append(f"{i}. {rec}")
        
        report.append("")
        report.append("=" * 80)
        
        return "\n".join(report)
    
    def get_cost_optimization_recommendations(self, cost_data: Dict) -> List[str]:
        """Generate cost optimization recommendations."""
        recommendations = []
        
        total_cost = cost_data['total_cost']
        
        # Check for high-cost resources
        for resource_type, data in cost_data['breakdown'].items():
            if data['total_cost'] > total_cost * 0.3:  # More than 30% of total cost
                if 'applicationGateways' in resource_type:
                    recommendations.append(
                        "Consider using Application Gateway Basic SKU instead of Standard v2 "
                        "if WAF features are not required. Potential savings: ~$100/month"
                    )
                elif 'bastionHosts' in resource_type:
                    recommendations.append(
                        "Consider using Azure Bastion only during business hours or "
                        "implement auto-shutdown. Potential savings: ~$50/month"
                    )
                elif 'virtualMachines' in resource_type:
                    recommendations.append(
                        "Implement auto-shutdown for VMs during non-business hours. "
                        "Potential savings: ~$15-20/month per VM"
                    )
        
        # General recommendations
        recommendations.extend([
            "Enable Azure Cost Management and Billing alerts to monitor spending",
            "Consider Reserved Instances for SQL VMs if running 24/7 (1-year commitment)",
            "Review and optimize storage types - consider Standard HDD for non-critical data",
            "Implement Azure Advisor recommendations for cost optimization",
            "Use Azure Policy to enforce cost controls and resource tagging",
            "Consider Azure Hybrid Benefit for Windows VMs if you have existing licenses"
        ])
        
        return recommendations
    
    def create_cost_chart(self, cost_data: Dict, output_file: str = "cost_breakdown.png"):
        """Create a visual cost breakdown chart."""
        try:
            # Prepare data for chart
            labels = []
            sizes = []
            colors = ['#ff9999', '#66b3ff', '#99ff99', '#ffcc99', '#ff99cc', '#c2c2f0', '#ffb3e6']
            
            for resource_type, data in cost_data['breakdown'].items():
                if data['total_cost'] > 0:
                    # Shorten resource type names for better display
                    short_name = resource_type.split('/')[-1].replace('Microsoft.', '')
                    labels.append(f"{short_name}\n${data['total_cost']:.2f}")
                    sizes.append(data['total_cost'])
            
            # Create pie chart
            plt.figure(figsize=(12, 8))
            wedges, texts, autotexts = plt.pie(
                sizes, 
                labels=labels, 
                colors=colors[:len(sizes)],
                autopct='%1.1f%%',
                startangle=90
            )
            
            plt.title(f'Azure 3-Tier Infrastructure Cost Breakdown\nTotal: ${cost_data["total_cost"]:.2f}/month', 
                     fontsize=16, fontweight='bold')
            
            # Improve text readability
            for autotext in autotexts:
                autotext.set_color('white')
                autotext.set_fontweight('bold')
            
            plt.axis('equal')
            plt.tight_layout()
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            plt.close()
            
            print(f"Cost breakdown chart saved as: {output_file}")
            
        except Exception as e:
            print(f"Error creating cost chart: {e}")
    
    def create_bar_chart(self, cost_data: Dict, output_file: str = "cost_bar_chart.png"):
        """Create a bar chart for cost breakdown."""
        try:
            # Prepare data for bar chart
            resource_types = []
            costs = []
            colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2']
            
            # Sort by cost descending
            sorted_breakdown = sorted(
                cost_data['breakdown'].items(),
                key=lambda x: x[1]['total_cost'],
                reverse=True
            )
            
            for resource_type, data in sorted_breakdown:
                if data['total_cost'] > 0:
                    # Shorten resource type names for better display
                    short_name = resource_type.split('/')[-1].replace('Microsoft.', '')
                    resource_types.append(short_name)
                    costs.append(data['total_cost'])
            
            # Create bar chart
            plt.figure(figsize=(14, 8))
            bars = plt.bar(resource_types, costs, color=colors[:len(resource_types)])
            
            # Add value labels on bars
            for bar, cost in zip(bars, costs):
                height = bar.get_height()
                plt.text(bar.get_x() + bar.get_width()/2., height + max(costs)*0.01,
                        f'${cost:.2f}', ha='center', va='bottom', fontweight='bold')
            
            plt.title('Azure 3-Tier Infrastructure - Monthly Cost by Resource Type', 
                     fontsize=16, fontweight='bold', pad=20)
            plt.xlabel('Resource Type', fontsize=12, fontweight='bold')
            plt.ylabel('Monthly Cost (USD)', fontsize=12, fontweight='bold')
            plt.xticks(rotation=45, ha='right')
            plt.grid(axis='y', alpha=0.3)
            
            # Add total cost annotation
            total_cost = cost_data['total_cost']
            plt.text(0.02, 0.98, f'Total Monthly Cost: ${total_cost:.2f}', 
                    transform=plt.gca().transAxes, fontsize=14, fontweight='bold',
                    bbox=dict(boxstyle="round,pad=0.3", facecolor="lightblue", alpha=0.7),
                    verticalalignment='top')
            
            plt.tight_layout()
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            plt.close()
            
            print(f"Cost bar chart saved as: {output_file}")
            
        except Exception as e:
            print(f"Error creating bar chart: {e}")
    
    def create_detailed_spreadsheet(self, cost_data: Dict, output_file: str = "detailed_cost_analysis.xlsx"):
        """Create a detailed Excel spreadsheet with multiple sheets."""
        try:
            with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
                # Sheet 1: Summary
                summary_data = {
                    'Metric': [
                        'Total Monthly Cost',
                        'Daily Average Cost',
                        'Hourly Average Cost',
                        'Total Resources',
                        'Analysis Date',
                        'Subscription ID',
                        'Resource Group'
                    ],
                    'Value': [
                        f"${cost_data['total_cost']:.2f}",
                        f"${cost_data['total_cost'] / 30:.2f}",
                        f"${cost_data['total_cost'] / (30 * 24):.2f}",
                        sum(len(data['resources']) for data in cost_data['breakdown'].values()),
                        datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                        self.subscription_id,
                        self.resource_group
                    ]
                }
                summary_df = pd.DataFrame(summary_data)
                summary_df.to_excel(writer, sheet_name='Summary', index=False)
                
                # Sheet 2: Cost by Resource Type
                resource_type_data = []
                for resource_type, data in cost_data['breakdown'].items():
                    if data['total_cost'] > 0:
                        percentage = (data['total_cost'] / cost_data['total_cost']) * 100
                        resource_type_data.append({
                            'Resource Type': resource_type.split('/')[-1].replace('Microsoft.', ''),
                            'Full Resource Type': resource_type,
                            'Monthly Cost': data['total_cost'],
                            'Percentage': percentage,
                            'Resource Count': len(data['resources'])
                        })
                
                resource_type_df = pd.DataFrame(resource_type_data)
                resource_type_df = resource_type_df.sort_values('Monthly Cost', ascending=False)
                resource_type_df.to_excel(writer, sheet_name='By Resource Type', index=False)
                
                # Sheet 3: Individual Resources
                individual_data = []
                for resource_type, data in cost_data['breakdown'].items():
                    for resource_name, cost in data['resources'].items():
                        percentage = (cost / cost_data['total_cost']) * 100
                        individual_data.append({
                            'Resource Name': resource_name,
                            'Resource Type': resource_type.split('/')[-1].replace('Microsoft.', ''),
                            'Full Resource Type': resource_type,
                            'Monthly Cost': cost,
                            'Percentage': percentage,
                            'Cost Category': self._get_cost_category(resource_type, cost)
                        })
                
                individual_df = pd.DataFrame(individual_data)
                individual_df = individual_df.sort_values('Monthly Cost', ascending=False)
                individual_df.to_excel(writer, sheet_name='Individual Resources', index=False)
                
                # Sheet 4: Cost Optimization Recommendations
                recommendations = self.get_cost_optimization_recommendations(cost_data)
                rec_data = []
                for i, rec in enumerate(recommendations, 1):
                    priority = self._get_priority(rec)
                    rec_data.append({
                        'Priority': priority,
                        'Recommendation': rec,
                        'Estimated Savings': self._get_estimated_savings(rec),
                        'Implementation Effort': self._get_effort_level(rec)
                    })
                
                rec_df = pd.DataFrame(rec_data)
                rec_df.to_excel(writer, sheet_name='Optimization Recommendations', index=False)
                
                # Sheet 5: Monthly Trends (placeholder for future data)
                trend_data = {
                    'Month': ['Current Month', 'Previous Month', '2 Months Ago', '3 Months Ago'],
                    'Total Cost': [cost_data['total_cost'], 0, 0, 0],
                    'Compute Cost': [sum(data['total_cost'] for rt, data in cost_data['breakdown'].items() 
                                       if 'Compute' in rt), 0, 0, 0],
                    'Network Cost': [sum(data['total_cost'] for rt, data in cost_data['breakdown'].items() 
                                        if 'Network' in rt), 0, 0, 0],
                    'Storage Cost': [sum(data['total_cost'] for rt, data in cost_data['breakdown'].items() 
                                        if 'Storage' in rt), 0, 0, 0]
                }
                trend_df = pd.DataFrame(trend_data)
                trend_df.to_excel(writer, sheet_name='Monthly Trends', index=False)
            
            print(f"Detailed Excel spreadsheet saved as: {output_file}")
            
        except Exception as e:
            print(f"Error creating Excel spreadsheet: {e}")
    
    def _get_cost_category(self, resource_type: str, cost: float) -> str:
        """Categorize resources by cost level."""
        if cost > 100:
            return "High Cost"
        elif cost > 50:
            return "Medium Cost"
        elif cost > 10:
            return "Low Cost"
        else:
            return "Minimal Cost"
    
    def _get_priority(self, recommendation: str) -> str:
        """Determine priority level for recommendations."""
        if "Application Gateway" in recommendation or "Bastion" in recommendation:
            return "High"
        elif "Reserved" in recommendation or "auto-shutdown" in recommendation:
            return "Medium"
        else:
            return "Low"
    
    def _get_estimated_savings(self, recommendation: str) -> str:
        """Extract estimated savings from recommendation text."""
        if "~$100" in recommendation:
            return "$100/month"
        elif "~$50" in recommendation:
            return "$50/month"
        elif "~$45" in recommendation:
            return "$45/month"
        elif "~$20-30" in recommendation:
            return "$20-30/month"
        else:
            return "Variable"
    
    def _get_effort_level(self, recommendation: str) -> str:
        """Determine implementation effort level."""
        if "Basic SKU" in recommendation or "auto-shutdown" in recommendation:
            return "Low"
        elif "Reserved" in recommendation or "Hybrid Benefit" in recommendation:
            return "Medium"
        else:
            return "High"
    
    def export_to_csv(self, cost_data: Dict, output_file: str = "cost_analysis.csv"):
        """Export cost data to CSV format."""
        try:
            rows = []
            
            for resource_type, data in cost_data['breakdown'].items():
                for resource_name, cost in data['resources'].items():
                    rows.append({
                        'Resource Type': resource_type,
                        'Resource Name': resource_name,
                        'Monthly Cost': cost,
                        'Percentage': (cost / cost_data['total_cost']) * 100
                    })
            
            df = pd.DataFrame(rows)
            df = df.sort_values('Monthly Cost', ascending=False)
            df.to_csv(output_file, index=False)
            
            print(f"Cost data exported to: {output_file}")
            
        except Exception as e:
            print(f"Error exporting to CSV: {e}")

def main():
    parser = argparse.ArgumentParser(description='Azure 3-Tier Infrastructure Cost Analysis')
    parser.add_argument('--subscription-id', required=True, help='Azure subscription ID')
    parser.add_argument('--resource-group', default='azure-3tier-rg-ypggv', help='Resource group name')
    parser.add_argument('--output-dir', default='.', help='Output directory for reports and charts')
    parser.add_argument('--chart', action='store_true', help='Generate cost breakdown pie chart')
    parser.add_argument('--bar-chart', action='store_true', help='Generate cost breakdown bar chart')
    parser.add_argument('--excel', action='store_true', help='Generate detailed Excel spreadsheet')
    parser.add_argument('--csv', action='store_true', help='Export cost data to CSV')
    parser.add_argument('--all', action='store_true', help='Generate all output formats')
    
    args = parser.parse_args()
    
    try:
        # Initialize cost analyzer
        analyzer = AzureCostAnalyzer(args.subscription_id, args.resource_group)
        
        # Get cost data
        print("Analyzing Azure infrastructure costs...")
        cost_data = analyzer.get_current_month_costs()
        
        # Generate report
        report = analyzer.generate_cost_report(cost_data)
        
        # Save report to file
        report_file = os.path.join(args.output_dir, f"cost_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt")
        with open(report_file, 'w') as f:
            f.write(report)
        
        print(f"\nCost analysis report saved to: {report_file}")
        print("\n" + report)
        
        # Generate additional outputs if requested
        if args.all or args.chart:
            chart_file = os.path.join(args.output_dir, "cost_breakdown.png")
            analyzer.create_cost_chart(cost_data, chart_file)
        
        if args.all or args.bar_chart:
            bar_chart_file = os.path.join(args.output_dir, "cost_bar_chart.png")
            analyzer.create_bar_chart(cost_data, bar_chart_file)
        
        if args.all or args.excel:
            excel_file = os.path.join(args.output_dir, "detailed_cost_analysis.xlsx")
            analyzer.create_detailed_spreadsheet(cost_data, excel_file)
        
        if args.all or args.csv:
            csv_file = os.path.join(args.output_dir, "cost_analysis.csv")
            analyzer.export_to_csv(cost_data, csv_file)
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
