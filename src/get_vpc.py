"""
Lambda function to retrieve VPC details by ID
"""
import json
import os
import boto3
from decimal import Decimal

ec2 = boto3.client('ec2')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['VPC_TABLE_NAME'])


def handler(event, context):
    """
    Retrieves VPC details from DynamoDB and optionally from AWS EC2
    """
    try:
        # Get VPC ID from path parameters
        vpc_id = event.get('pathParameters', {}).get('vpc_id')
        
        if not vpc_id:
            return error_response(400, 'vpc_id is required')
        
        # Get VPC metadata from DynamoDB
        response = table.get_item(Key={'vpc_id': vpc_id})
        
        if 'Item' not in response:
            return error_response(404, f'VPC {vpc_id} not found in database')
        
        vpc_metadata = response['Item']
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(vpc_metadata, default=decimal_default)
        }
        
    except Exception as e:
        print(f"Error retrieving VPC: {str(e)}")
        return error_response(500, f"Internal server error: {str(e)}")


def decimal_default(obj):
    """JSON serializer for Decimal types"""
    if isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    raise TypeError


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
