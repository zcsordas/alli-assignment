"""
Lambda function to create a VPC with multiple subnets
"""
import json
import os
import boto3
from datetime import datetime
from decimal import Decimal
import traceback

ec2 = boto3.client('ec2')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['VPC_TABLE_NAME'])


def handler(event, context):
    """
    Creates a VPC with multiple subnets based on the request body
    
    Expected request body:
    {
        "cidr_block": "10.0.0.0/16",
        "subnets": [
            {"cidr": "10.0.1.0/24", "availability_zone": "us-east-1a", "name": "public-1"},
            {"cidr": "10.0.2.0/24", "availability_zone": "us-east-1b", "name": "public-2"}
        ],
        "name": "MyVPC",
        "enable_dns_support": true,
        "enable_dns_hostnames": true
    }
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        # Validate required fields
        cidr_block = body.get('cidr_block')
        subnets_config = body.get('subnets', [])
        vpc_name = body.get('name', 'VPC-API-Created')
        enable_dns_support = body.get('enable_dns_support', True)
        enable_dns_hostnames = body.get('enable_dns_hostnames', True)
        
        if not cidr_block:
            return error_response(400, 'cidr_block is required')
        
        if not subnets_config or len(subnets_config) < 1:
            return error_response(400, 'At least one subnet configuration is required')
        
        # Create VPC
        vpc_response = ec2.create_vpc(
            CidrBlock=cidr_block,
            TagSpecifications=[
                {
                    'ResourceType': 'vpc',
                    'Tags': [
                        {'Key': 'Name', 'Value': vpc_name},
                        {'Key': 'ManagedBy', 'Value': 'VPC-API'},
                        {'Key': 'CreatedAt', 'Value': datetime.utcnow().isoformat()}
                    ]
                }
            ]
        )
        
        vpc_id = vpc_response['Vpc']['VpcId']
        
        # Enable DNS support and hostnames
        if enable_dns_support:
            ec2.modify_vpc_attribute(
                VpcId=vpc_id,
                EnableDnsSupport={'Value': True}
            )
        
        if enable_dns_hostnames:
            ec2.modify_vpc_attribute(
                VpcId=vpc_id,
                EnableDnsHostnames={'Value': True}
            )
        
        # Create subnets
        created_subnets = []
        for subnet_config in subnets_config:
            subnet_cidr = subnet_config.get('cidr')
            availability_zone = subnet_config.get('availability_zone')
            subnet_name = subnet_config.get('name', 'Subnet')
            
            if not subnet_cidr:
                # Cleanup VPC if subnet creation fails
                cleanup_vpc(vpc_id)
                return error_response(400, 'Each subnet must have a cidr field')
            
            subnet_params = {
                'VpcId': vpc_id,
                'CidrBlock': subnet_cidr,
                'TagSpecifications': [
                    {
                        'ResourceType': 'subnet',
                        'Tags': [
                            {'Key': 'Name', 'Value': subnet_name},
                            {'Key': 'ManagedBy', 'Value': 'VPC-API'},
                            {'Key': 'VpcName', 'Value': vpc_name}
                        ]
                    }
                ]
            }
            
            if availability_zone:
                subnet_params['AvailabilityZone'] = availability_zone
            
            subnet_response = ec2.create_subnet(**subnet_params)
            
            created_subnets.append({
                'subnet_id': subnet_response['Subnet']['SubnetId'],
                'cidr_block': subnet_response['Subnet']['CidrBlock'],
                'availability_zone': subnet_response['Subnet']['AvailabilityZone'],
                'name': subnet_name
            })
        
        # Store metadata in DynamoDB
        created_at = datetime.utcnow().isoformat()
        vpc_metadata = {
            'vpc_id': vpc_id,
            'cidr_block': cidr_block,
            'name': vpc_name,
            'subnets': created_subnets,
            'enable_dns_support': enable_dns_support,
            'enable_dns_hostnames': enable_dns_hostnames,
            'created_at': created_at,
            'region': os.environ['REGION'],
            'state': vpc_response['Vpc']['State']
        }
        
        table.put_item(Item=vpc_metadata)
        
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'VPC created successfully',
                'vpc': vpc_metadata
            }, default=str)
        }
        
    except ec2.exceptions.ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        print(f"AWS Error: {error_code} - {error_message}")
        return error_response(400, f"AWS Error: {error_message}")
    
    except Exception as e:
        print(f"Error creating VPC: {str(e)}")
        print(traceback.format_exc())
        return error_response(500, f"Internal server error: {str(e)}")


def cleanup_vpc(vpc_id):
    """Clean up VPC and its resources if creation fails"""
    try:
        # Delete all subnets
        subnets = ec2.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
        for subnet in subnets['Subnets']:
            ec2.delete_subnet(SubnetId=subnet['SubnetId'])
        
        # Delete VPC
        ec2.delete_vpc(VpcId=vpc_id)
        print(f"Cleaned up VPC {vpc_id} after error")
    except Exception as cleanup_error:
        print(f"Error during cleanup: {str(cleanup_error)}")


def error_response(status_code, message):
    """Return formatted error response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'error': message
        })
    }
