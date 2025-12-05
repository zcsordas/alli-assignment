"""
Lambda function to list all created VPCs
"""
import json
import os
import boto3
from decimal import Decimal
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['VPC_TABLE_NAME'])


def handler(event, context):
    """
    Lists all VPCs stored in DynamoDB with optional filtering
    """
    try:
        # Get query parameters
        query_params = event.get('queryStringParameters') or {}
        limit = int(query_params.get('limit', 100))
        
        # Scan DynamoDB table
        scan_params = {
            'Limit': min(limit, 1000)  # Max 1000 items
        }
        
        # Optional filter by name
        name_filter = query_params.get('name')
        if name_filter:
            scan_params['FilterExpression'] = Attr('name').contains(name_filter)
        
        response = table.scan(**scan_params)
        vpcs = response.get('Items', [])
        
        # Sort by created_at (newest first)
        vpcs.sort(key=lambda x: x.get('created_at', ''), reverse=True)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'count': len(vpcs),
                'vpcs': vpcs,
                'has_more': 'LastEvaluatedKey' in response
            }, default=decimal_default)
        }
        
    except Exception as e:
        print(f"Error listing VPCs: {str(e)}")
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
