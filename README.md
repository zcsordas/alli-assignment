# VPC Management API

A fully serverless API for creating and managing AWS VPCs with multiple subnets, built using Terraform.

**This version is configured for LocalStack (local testing) without authentication. See deployment instructions below.**

## Assignment Requirements

**Original Exercise:**
> Create an API based on AWS services that can create a VPC with multiple subnets and store the results. The API should be protected with an authentication layer. Automate the setup as much as possible using AWS serverless services.

**What's Accomplished:**

✅ **API Implementation**: RESTful API with full CRUD operations (Create, Read, List, Delete VPCs)  
✅ **VPC Management**: Creates VPCs with configurable CIDR blocks and multiple subnets across availability zones  
✅ **Data Persistence**: Stores VPC metadata in DynamoDB with indexing for efficient queries  
✅ **Serverless Architecture**: API Gateway + Lambda + DynamoDB (fully serverless)  
✅ **Infrastructure as Code**: Fully automated deployment using Terraform  
✅ **Local Testing Environment**: LocalStack setup for development without AWS account  
⚠️ **Authentication**: Simplified for LocalStack (Cognito auth architecture designed but not active in current version)

**Additional Features Beyond Requirements:**
- Comprehensive error handling and validation
- VPC resource cleanup (subnets, route tables, internet gateways)
- Automated testing script
- Cross-platform support (Linux/Windows)
- Well-documented API with examples

## Architecture

- **API Gateway**: RESTful API (no authentication for LocalStack)
- **AWS Lambda**: Python 3.11 functions for VPC operations
- **Amazon DynamoDB**: Metadata storage for created VPCs
- **AWS EC2**: VPC and subnet creation
- **LocalStack**: Local AWS cloud emulation

## Features

✅ Create VPCs with multiple subnets  
✅ Retrieve VPC details by ID  
✅ List all created VPCs  
✅ Delete VPCs and associated resources  
✅ Fully automated deployment with Terraform  
✅ Local testing with LocalStack (no AWS account needed)  
✅ No authentication required (simplified for testing)  

## Prerequisites

### For LocalStack (Local Testing - No AWS Account Needed)

1. **Docker** (for LocalStack)
   
   **Linux:**
   ```bash
   sudo apt install docker.io
   sudo usermod -aG docker $USER
   # Log out and back in
   ```
   
   **Windows:**
   - Download and install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
   - Enable WSL 2 backend during installation
   - Start Docker Desktop

2. **LocalStack**
   
   **Linux:**
   ```bash
   # Create virtual environment
   python3 -m venv venv
   source venv/bin/activate
   
   # Install LocalStack
   pip install localstack
   ```
   
   **Windows (PowerShell):**
   ```powershell
   # Create virtual environment
   python -m venv venv
   .\venv\Scripts\Activate.ps1
   
   # Install LocalStack
   pip install localstack
   ```

3. **Terraform** (>= 1.0)
   
   **Linux:**
   ```bash
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```
   
   **Windows:**
   - Download from [Terraform Downloads](https://www.terraform.io/downloads)
   - Extract `terraform.exe` to a folder (e.g., `C:\terraform`)
   - Add folder to System PATH environment variable

4. **jq** (for testing scripts)
   
   **Linux:**
   ```bash
   sudo apt install jq
   ```
   
   **Windows:**
   - Download from [jq releases](https://github.com/stedolan/jq/releases)
   - Rename to `jq.exe` and add to PATH
   - Or use: `choco install jq` (if using Chocolatey)

5. **Python 3.11** or later
   
   **Linux:** Usually pre-installed, or `sudo apt install python3.11`
   
   **Windows:** Download from [python.org](https://www.python.org/downloads/)

## Project Structure

```
.
├── terraform/
│   ├── main.tf               # Provider configuration
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Output values
│   ├── dynamodb.tf           # DynamoDB table
│   ├── cognito.tf            # Cognito user pool
│   ├── iam.tf                # IAM roles and policies
│   ├── lambda.tf             # Lambda functions
│   └── api_gateway.tf        # API Gateway configuration
├── src/
│   ├── create_vpc.py         # Lambda: Create VPC
│   ├── get_vpc.py            # Lambda: Get VPC by ID
│   ├── list_vpcs.py          # Lambda: List all VPCs
│   ├── delete_vpc.py         # Lambda: Delete VPC
│   └── requirements.txt      # Python dependencies (boto3 is built-in)
├── scripts/
│   ├── deploy.sh             # Deployment helper script
│   ├── create_user.sh        # Create Cognito test user
│   └── test_api.sh           # API testing script
├── examples/
│   └── api_examples.json     # Example API requests
└── README.md
```

## Deployment to LocalStack

### Step 1: Start LocalStack

```bash
# In terminal 1 - start LocalStack
localstack start

# Or run in background
localstack start -d

# Verify it's running
curl http://localhost:4566/_localstack/health
```

### Step 2: Deploy with Terraform

```bash
# In terminal 2
cd terraform

# Initialize Terraform
terraform init

# Deploy to LocalStack
terraform apply -auto-approve
```

### Step 3: Get API Endpoint

```bash
# Get the API endpoint
terraform output api_endpoint_localstack

# Example output:
# http://localhost:4566/restapis/xxxxx/prod/_user_request_
```

## Configuration

After deployment, view outputs:

```bash
cd terraform
terraform output

# Outputs:
# api_endpoint_localstack = "http://localhost:4566/restapis/xxxxx/prod/_user_request_"
# dynamodb_table_name = "VpcMetadata"
```

## API Usage

**Note:** No authentication required for LocalStack version.

### 1. Create VPC

**Endpoint**: `POST /vpc`

**Request Body**:
```json
{
  "cidr_block": "10.0.0.0/16",
  "name": "MyVPC",
  "enable_dns_support": true,
  "enable_dns_hostnames": true,
  "subnets": [
    {
      "cidr": "10.0.1.0/24",
      "availability_zone": "us-east-1a",
      "name": "public-subnet-1"
    },
    {
      "cidr": "10.0.2.0/24",
      "availability_zone": "us-east-1b",
      "name": "public-subnet-2"
    }
  ]
}
```

**Example**:
```bash
curl -X POST http://localhost:4566/restapis/xxxxx/prod/_user_request_/vpc \
  -H "Content-Type: application/json" \
  -d '{
    "cidr_block": "10.0.0.0/16",
    "name": "MyVPC",
    "subnets": [
      {"cidr": "10.0.1.0/24", "availability_zone": "us-east-1a", "name": "subnet-1"}
    ]
  }'
```

**Response**:
```json
{
  "message": "VPC created successfully",
  "vpc": {
    "vpc_id": "vpc-0123456789abcdef",
    "cidr_block": "10.0.0.0/16",
    "name": "MyVPC",
    "subnets": [
      {
        "subnet_id": "subnet-0123456789abcdef",
        "cidr_block": "10.0.1.0/24",
        "availability_zone": "us-east-1a",
        "name": "subnet-1"
      }
    ],
    "created_at": "2025-11-27T12:00:00.000000",
    "region": "us-east-1"
  }
}
```

### 2. Get VPC Details

**Endpoint**: `GET /vpc/{vpc_id}`

**Example**:
```bash
curl http://localhost:4566/restapis/xxxxx/prod/_user_request_/vpc/vpc-0123456789abcdef
```

### 3. List All VPCs

**Endpoint**: `GET /vpcs`

**Example**:
```bash
curl http://localhost:4566/restapis/xxxxx/prod/_user_request_/vpcs
```

**Response**:
```json
{
  "count": 2,
  "vpcs": [
    {
      "vpc_id": "vpc-xxx",
      "name": "MyVPC",
      "cidr_block": "10.0.0.0/16",
      "created_at": "2025-11-27T12:00:00"
    }
  ],
  "has_more": false
}
```

### 4. Delete VPC

**Endpoint**: `DELETE /vpc/{vpc_id}`

**Example**:
```bash
curl -X DELETE http://localhost:4566/restapis/xxxxx/prod/_user_request_/vpc/vpc-0123456789abcdef
```

## Security Notes

**LocalStack Version (Current)**:
- ⚠️ **No Authentication**: Simplified for local testing
- ✅ **IAM**: Lambda functions have least-privilege IAM roles
- ✅ **VPC Tagging**: Each VPC is tagged with metadata

**Production Considerations**:
- Would add AWS Cognito with JWT tokens
- Would enforce HTTPS via API Gateway
- Would implement per-user authorization

## Cleanup

### Stop LocalStack
```bash
# Stop LocalStack
localstack stop

# Or if running in Docker
docker stop localstack
```

### Destroy Terraform Resources
```bash
cd terraform
terraform destroy -auto-approve
```

**Note**: LocalStack data is ephemeral - stopping LocalStack clears all resources.

## Troubleshooting

### LocalStack Not Starting
```bash
# Check if port 4566 is already in use
lsof -i :4566

# Check LocalStack status
localstack status

# View LocalStack logs
localstack logs
```

### Terraform Errors
```bash
# Validate configuration
terraform validate

# Clean and re-init
rm -rf .terraform terraform.tfstate*
terraform init
```

### API Returns Errors
```bash
# Check LocalStack logs
localstack logs | grep -i error

# Verify Lambda functions deployed
terraform state list | grep lambda

# Test connectivity
curl http://localhost:4566/_localstack/health
```

### View Lambda Logs (LocalStack)
```bash
# View all LocalStack logs
localstack logs -f

# Or check specific function logs in LocalStack dashboard
# http://localhost:4566/_localstack/logs
```

## Development

### Project Structure (LocalStack Version)

```
terraform/
├── main.tf              # Removed (using localstack.tf)
├── localstack.tf        # LocalStack provider configuration
├── variables.tf         # Input variables
├── dynamodb.tf          # DynamoDB table
├── iam.tf              # IAM roles and policies
├── lambda.tf           # Lambda functions (permissions commented out)
├── api_gateway_simple.tf # API Gateway without auth
```

### Adding New Features

1. Update Terraform files (e.g., add new endpoint in `api_gateway_simple.tf`)
2. Create Python handler in `src/`
3. Update IAM policies if needed in `iam.tf`
4. Deploy: `terraform apply -auto-approve`
5. Test with `./scripts/test_localstack.sh`

### Testing Lambda Functions Locally

```bash
# Activate virtual environment
source venv/bin/activate

# Test Python code directly
cd src
python3 << EOF
import json
from list_vpcs import handler
result = handler({}, {})
print(json.dumps(result, indent=2))
EOF
```

## Design Decisions

1. **LocalStack for Testing**: No AWS account needed, free, fast iteration
2. **No Authentication (for now)**: Simplified for local testing/demo
3. **DynamoDB over RDS**: Serverless, auto-scaling, works in LocalStack free tier
4. **Separate Lambda per endpoint**: Better separation of concerns, easier debugging
5. **VPC tagging**: Enables tracking and cleanup
6. **Terraform**: Industry standard IaC tool, better for portfolios, multi-cloud skills

## License

MIT License - See LICENSE file for details
