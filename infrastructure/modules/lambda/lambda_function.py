import json
import boto3
import os
from datetime import datetime

s3_client = boto3.client('s3')
BUCKET_NAME = os.environ['LOGS_BUCKET_NAME']

def lambda_handler(event, context):
    """
    Audit Lambda function triggered on each API call
    Stores audit logs in S3
    """
    try:
        # Parse the event
        audit_data = event if isinstance(event, dict) else json.loads(event)
        
        # Add Lambda processing timestamp
        audit_data['audit_timestamp'] = datetime.utcnow().isoformat()
        audit_data['lambda_request_id'] = context.request_id
        
        # Create S3 key with date partitioning
        now = datetime.utcnow()
        s3_key = f"audit-logs/{now.year}/{now.month:02d}/{now.day:02d}/{context.request_id}.json"
        
        # Store in S3
        s3_client.put_object(
            Bucket=BUCKET_NAME,
            Key=s3_key,
            Body=json.dumps(audit_data, indent=2),
            ContentType='application/json'
        )
        
        print(f"Audit log stored: {s3_key}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Audit log stored successfully',
                's3_key': s3_key
            })
        }
        
    except Exception as e:
        print(f"Error processing audit: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error storing audit log',
                'error': str(e)
            })
        }
