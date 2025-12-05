"""
Lambda function to delete a VPC and its resources
"""
import json
import os
import boto3

ec2 = boto3.client('ec2')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['VPC_TABLE_NAME'])


def handler(event, context):
    """
    Deletes a VPC and all its associated resources
    """
    try:
        # Get VPC ID from path parameters
        vpc_id = event.get('pathParameters', {}).get('vpc_id')
        
        if not vpc_id:
            return error_response(400, 'vpc_id is required')
        
        # Check if VPC exists in database
        response = table.get_item(Key={'vpc_id': vpc_id})
        
        if 'Item' not in response:
            return error_response(404, f'VPC {vpc_id} not found in database')
        
        # Delete AWS resources
        deletion_log = []
        
        try:
            # 1. Delete subnets
            subnets = ec2.describe_subnets(
                Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}]
            )
            
            for subnet in subnets['Subnets']:
                subnet_id = subnet['SubnetId']
                ec2.delete_subnet(SubnetId=subnet_id)
                deletion_log.append(f"Deleted subnet {subnet_id}")
            
            # 2. Detach and delete internet gateways
            igws = ec2.describe_internet_gateways(
                Filters=[{'Name': 'attachment.vpc-id', 'Values': [vpc_id]}]
            )
            
            for igw in igws['InternetGateways']:
                igw_id = igw['InternetGatewayId']
                ec2.detach_internet_gateway(InternetGatewayId=igw_id, VpcId=vpc_id)
                ec2.delete_internet_gateway(InternetGatewayId=igw_id)
                deletion_log.append(f"Deleted internet gateway {igw_id}")
            
            # 3. Delete route tables (except main)
            route_tables = ec2.describe_route_tables(
                Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}]
            )
            
            for rt in route_tables['RouteTables']:
                # Skip main route table
                is_main = any(assoc.get('Main', False) for assoc in rt.get('Associations', []))
                if not is_main:
                    rt_id = rt['RouteTableId']
                    ec2.delete_route_table(RouteTableId=rt_id)
                    deletion_log.append(f"Deleted route table {rt_id}")
            
            # 4. Delete VPC
            ec2.delete_vpc(VpcId=vpc_id)
            deletion_log.append(f"Deleted VPC {vpc_id}")
            
        except ec2.exceptions.ClientError as e:
            error_message = e.response['Error']['Message']
            deletion_log.append(f"AWS Error: {error_message}")
            # Continue to delete from DynamoDB even if AWS deletion fails
        
        # Delete from DynamoDB
        table.delete_item(Key={'vpc_id': vpc_id})
        deletion_log.append(f"Deleted VPC metadata from database")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': f'VPC {vpc_id} deleted successfully',
                'deletion_log': deletion_log
            })
        }
        
    except Exception as e:
        print(f"Error deleting VPC: {str(e)}")
        return error_response(500, f"Internal server error: {str(e)}")


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
