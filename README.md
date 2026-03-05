# lambda-create-bucket

## Objective

Lambda function can create a bucket but only in the same account
where the lambda is deployed

## Rules

1. Do not run sudo commands to implement these requirements
2. Do not change files outside of this directory
3. Do not do more than you are asked to do
4. Do not delete anything without confirming
5. Do not guess or speculate, validate your actions first
6. If instructions are unclear, ask for clarification
7. Do not use subshells
8. Do not hide errors with /dev/null
9. Do not hide errors with || 
10. Implement proper error handling that checks error output
11. In install scripts: If a resource exists update it otherwise create it
12. Do NOT run the scripts you do not have permission
13. The scripts are run on another machine not this one
14. DO NOT try to run AWS commands
15. Fix the SCRIPTS do not make manual changes
16. Ask me to run anything that needs to be checked or tested after scripts run

## Requirements

1 Create directories
1.1 Create src directory 
1.2 Create src/install directory
1.3 Create src/code directory

2 Create Variables
2.1 create src/init.sh
2.2 Initialize the following variables in init.sh:
2.2.1 LAMBDA="lambda-create-bucket"
2.2.2 BUCKET=$LAMBDA
2.2.3 CLOUDWATCH_LOG_GROUP=$LAMBDA
2.2.4 LAMBDA_ROLE=$LAMBDA-lambda-role
2.2.5 LAMBDA_ROLE_POLICY=$LAMBDA-lambda-policy
2.2.6 REGION=(current cloudshell region)

3 Create install.sh script
3.1 Create install.sh
3.2 source src/init.sh
3.3 execute all files in src/install in the order created below

4 Create S3 bucket deployment script
4.1 create src/install/s3-bucket.sh
4.2 in that script create or update an s3 bucket with an AWS cli command named $BUCKET
4.3 use LocationConstraint for bucket creation in non-us-east-1 regions
4.4 use --no-cli-pager flag on all AWS CLI commands
4.5 enable versioning on the bucket
4.6 configure lifecycle policy to keep only 5 versions with NoncurrentVersionExpiration after 1 day

5 Create CloudWatch log group deployment script
5.1 create src/install/cloudwatch-log-group.sh
5.2 in that script create or update a cloudwatch log group with the name $CLOUDWATCH_LOG_GROUP

6 Create Lambda Role deployment script
6.1 create src/install/lambda-role.sh
6.2 in the script create or update an IAM role for the $LAMBDA named $LAMBDA_ROLE
6.3 give the role the default Lambda trust policy

7 Create Lambda policy deployment script
7.1 create src/install/lambda-policy.sh
7.2 in the script create or update $LAMBDA_ROLE_POLICY with default Lambda permissions
7.3 the policy should allow writing logs to $CLOUDWATCH_LOG_GROUP
7.4 the policy should allow creating S3 buckets in the same account
7.5 the lambda policy should only have the exact permissions it needs to do what is in the code in src/code
7.6 wait 10 seconds after attaching policy to role for IAM propagation

8 Write the Lambda code
8.1 create the lambda function code in src/code
8.2 the function accepts event['bucketName'] parameter
8.3 the function creates an S3 bucket with the provided name
8.4 the function enables versioning on the created bucket
8.5 the function configures lifecycle policy to keep only 5 versions with NoncurrentVersionExpiration after 1 day on the created bucket
8.6 the function must use the latest Python runtime available in AWS Lambda
8.7 use boto3 for S3 operations
8.8 log all actions, errors to console for CloudWatch Logs capture
8.9 validate bucket name follows S3 naming rules from latest AWS documentation
8.10 return success response with bucket name and region
8.11 create bucket in same region as Lambda function

9 Create the lambda function deployment script
9.1 create src/install/lambda.sh
9.2 in that script deploy the lambda function with the code in src/code
9.3 The lambda function should be assigned the role $LAMBDA_ROLE
9.4 Configure the Lambda with 512 MB memory
9.5 Configure the Lambda with 30 second timeout
9.6 Configure the Lambda with arm64 architecture

10 create run.sh
10.1 create run.sh
10.2 prompt user for bucket name
10.3 add a command to execute the lambda function with bucketName parameter

11 create cleanup.sh
11.1 create cleanup.sh in the root
11.2 delete all AWS resources created by the install scripts in reverse order
11.3 delete Lambda function
11.4 delete Lambda role and policy
11.5 delete CloudWatch log group
11.6 delete S3 bucket and all contents

12 Error Handling
12.1 Do not hide errors with /dev/null
12.2 Do not hide errors with ||
12.3 Implement proper error handling that checks error output
12.4 Log all errors to CloudWatch
12.5 Display all errors
12.6 Log all output to CloudWatch

13 KMS Encryption Support
13.1 run.sh prompts for optional KMS key ARN
13.2 Lambda accepts optional event['kmsKeyArn'] parameter
13.3 Lambda applies KMS encryption to bucket if KMS key ARN provided
13.4 Lambda policy includes s3:PutEncryptionConfiguration permission
13.5 Lambda policy includes kms:Decrypt and kms:GenerateDataKey permissions
13.6 KMS key must be in same region as Lambda and bucket
13.7 KMS key policy must allow Lambda role to use the key


