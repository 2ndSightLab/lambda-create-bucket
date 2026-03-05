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
        kms_key_arn = event.get('kmsKeyArn')
        
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
        print(f"Creating or updating bucket: {bucket_name} in region: {region}")
        
        bucket_created = False
        try:
            if region == 'us-east-1':
                s3_client.create_bucket(Bucket=bucket_name)
            else:
                s3_client.create_bucket(
                    Bucket=bucket_name,
                    CreateBucketConfiguration={'LocationConstraint': region}
                )
            bucket_created = True
            print(f"Bucket {bucket_name} created successfully in {region}")
        except s3_client.exceptions.BucketAlreadyOwnedByYou:
            print(f"Bucket {bucket_name} already exists, updating configuration")
        except s3_client.exceptions.BucketAlreadyExists:
            error_msg = f"Bucket {bucket_name} already exists and is owned by another account"
            print(f"ERROR: {error_msg}")
            return {
                'statusCode': 409,
                'body': json.dumps({
                    'error': error_msg
                })
            }
        
        try:
            print(f"Enabling versioning on bucket: {bucket_name}")
            s3_client.put_bucket_versioning(
                Bucket=bucket_name,
                VersioningConfiguration={'Status': 'Enabled'}
            )
            print(f"Versioning enabled on bucket: {bucket_name}")
        except Exception as e:
            error_msg = f"Failed to enable versioning: {str(e)}"
            print(f"ERROR: {error_msg}")
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'error': error_msg
                })
            }
        
        if kms_key_arn:
            try:
                print(f"Enabling KMS encryption on bucket: {bucket_name} with key: {kms_key_arn}")
                s3_client.put_bucket_encryption(
                    Bucket=bucket_name,
                    ServerSideEncryptionConfiguration={
                        'Rules': [
                            {
                                'ApplyServerSideEncryptionByDefault': {
                                    'SSEAlgorithm': 'aws:kms',
                                    'KMSMasterKeyID': kms_key_arn
                                },
                                'BucketKeyEnabled': True
                            }
                        ]
                    }
                )
                print(f"KMS encryption enabled on bucket: {bucket_name}")
            except Exception as e:
                error_msg = f"Failed to enable KMS encryption: {str(e)}"
                print(f"ERROR: {error_msg}")
                return {
                    'statusCode': 500,
                    'body': json.dumps({
                        'error': error_msg
                    })
                }
        
        try:
            print(f"Configuring lifecycle policy on bucket: {bucket_name}")
            s3_client.put_bucket_lifecycle_configuration(
                Bucket=bucket_name,
                LifecycleConfiguration={
                    'Rules': [
                        {
                            'ID': 'KeepOnly5Versions',
                            'Filter': {'Prefix': ''},
                            'Status': 'Enabled',
                            'NoncurrentVersionExpiration': {
                                'NoncurrentDays': 1,
                                'NewerNoncurrentVersions': 5
                            }
                        }
                    ]
                }
            )
            print(f"Lifecycle policy configured on bucket: {bucket_name}")
        except Exception as e:
            error_msg = f"Failed to configure lifecycle policy: {str(e)}"
            print(f"ERROR: {error_msg}")
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'error': error_msg
                })
            }
        
        action = 'created' if bucket_created else 'updated'
        print(f"SUCCESS: Bucket {bucket_name} {action} and fully configured in {region}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Bucket {action} successfully',
                'bucketName': bucket_name,
                'region': region
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
