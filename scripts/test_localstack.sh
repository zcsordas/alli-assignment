#!/bin/bash

# LocalStack API Testing Script (No Authentication Required)

set -e

# Get API endpoint from Terraform
API_ENDPOINT=$(cd terraform && terraform output -raw api_endpoint_localstack 2>/dev/null)

if [ -z "$API_ENDPOINT" ]; then
    echo "❌ Could not get API endpoint. Make sure Terraform is deployed."
    exit 1
fi

echo "✅ Using API endpoint: $API_ENDPOINT"
echo ""

# Test 1: List VPCs (should be empty initially)
echo "📋 Test 1: Listing VPCs (should be empty)..."
curl -s "$API_ENDPOINT/vpcs" | jq '.' || echo "Response: $(curl -s $API_ENDPOINT/vpcs)"

echo ""
echo "---"
echo ""

# Test 2: Create a VPC
echo "🏗️  Test 2: Creating a VPC..."
VPC_RESPONSE=$(curl -s -X POST "$API_ENDPOINT/vpc" \
    -H "Content-Type: application/json" \
    -d '{
        "cidr_block": "10.0.0.0/16",
        "name": "LocalStackTestVPC",
        "enable_dns_support": true,
        "enable_dns_hostnames": true,
        "subnets": [
            {
                "cidr": "10.0.1.0/24",
                "availability_zone": "us-east-1a",
                "name": "test-subnet-1"
            },
            {
                "cidr": "10.0.2.0/24",
                "availability_zone": "us-east-1b",
                "name": "test-subnet-2"
            }
        ]
    }')

echo "$VPC_RESPONSE" | jq '.' 2>/dev/null || echo "Response: $VPC_RESPONSE"

# Extract VPC ID
VPC_ID=$(echo "$VPC_RESPONSE" | jq -r '.vpc.vpc_id' 2>/dev/null)

if [ "$VPC_ID" == "null" ] || [ -z "$VPC_ID" ]; then
    echo ""
    echo "❌ Failed to create VPC. Check the response above for errors."
    exit 1
fi

echo ""
echo "✅ VPC created with ID: $VPC_ID"
echo ""
echo "---"
echo ""

# Test 3: Get VPC details
echo "🔍 Test 3: Getting VPC details..."
curl -s "$API_ENDPOINT/vpc/$VPC_ID" | jq '.' 2>/dev/null || curl -s "$API_ENDPOINT/vpc/$VPC_ID"

echo ""
echo "---"
echo ""

# Test 4: List VPCs again (should show the created VPC)
echo "📋 Test 4: Listing VPCs (should show 1 VPC)..."
curl -s "$API_ENDPOINT/vpcs" | jq '.' 2>/dev/null || curl -s "$API_ENDPOINT/vpcs"

echo ""
echo "---"
echo ""

# Test 5: Delete VPC
echo "🗑️  Test 5: Deleting VPC..."
curl -s -X DELETE "$API_ENDPOINT/vpc/$VPC_ID" | jq '.' 2>/dev/null || curl -s -X DELETE "$API_ENDPOINT/vpc/$VPC_ID"

echo ""
echo "---"
echo ""

# Test 6: Verify deletion
echo "📋 Test 6: Listing VPCs (should be empty again)..."
curl -s "$API_ENDPOINT/vpcs" | jq '.' 2>/dev/null || curl -s "$API_ENDPOINT/vpcs"

echo ""
echo ""
echo "✅ All tests completed!"
echo ""
