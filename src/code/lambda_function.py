import json
import boto3
import re
import os

s3_client = boto3.client('s3')

def validate_bucket_name(bucket_name):
    if not bucket_name or len(bucket_name) < 3 or len(bucket_name) > 63:
        return False, "Bucket name must be between 3 and 63 characters"
    
    sanitized = re.sub(r'[^a-z0-9.-]', '', bucket_name)
    if sanitized != bucket_name:
        return False, "Bucket name contains invalid characters"
    
    return True, "Valid"

def lambda_handler(event, context):
    """
    Lambda function to create an S3 bucket
    """
    try:
        bucket_name = event.get('bucketName')
        
        if not bucket_name:
            print("ERROR: bucketName parameter is required")
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'bucketName parameter is required'
                })
            }
        
        print(f"Validating bucket name: {bucket_name}")
        is_valid, message = validate_bucket_name(bucket_name)
        
        if not is_valid:
            print(f"ERROR: Invalid bucket name - {message}")
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': f'Invalid bucket name: {message}'
                })
            }
        
        region = os.environ.get('AWS_REGION', 'us-east-1')
        print(f"Creating bucket: {bucket_name} in region: {region}")
        
        if region == 'us-east-1':
            s3_client.create_bucket(Bucket=bucket_name)
        else:
            s3_client.create_bucket(
                Bucket=bucket_name,
                CreateBucketConfiguration={'LocationConstraint': region}
            )
        
        print(f"SUCCESS: Bucket {bucket_name} created successfully in {region}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Bucket created successfully',
                'bucketName': bucket_name,
                'region': region
            })
        }
        
    except s3_client.exceptions.BucketAlreadyExists:
        error_msg = f"Bucket {bucket_name} already exists and is owned by another account"
        print(f"ERROR: {error_msg}")
        return {
            'statusCode': 409,
            'body': json.dumps({
                'error': error_msg
            })
        }
    
    except s3_client.exceptions.BucketAlreadyOwnedByYou:
        error_msg = f"Bucket {bucket_name} already exists in your account"
        print(f"ERROR: {error_msg}")
        return {
            'statusCode': 409,
            'body': json.dumps({
                'error': error_msg
            })
        }
    
    except Exception as e:
        error_msg = f"Failed to create bucket: {str(e)}"
        print(f"ERROR: {error_msg}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_msg
            })
        }
