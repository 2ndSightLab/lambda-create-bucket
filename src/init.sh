#!/bin/bash

LAMBDA="env-deploy-bucket"
BUCKET=$LAMBDA
CLOUDWATCH_LOG_GROUP=$LAMBDA
LAMBDA_ROLE=$LAMBDA-lambda-role
LAMBDA_ROLE_POLICY=$LAMBDA-lambda-policy

# Try multiple methods to get region
if [ -n "$AWS_REGION" ]; then
  REGION=$AWS_REGION
elif [ -n "$AWS_DEFAULT_REGION" ]; then
  REGION=$AWS_DEFAULT_REGION
else
  # Try EC2 instance metadata (IMDSv2)
  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" --connect-timeout 1 2>/dev/null)
  if [ -n "$TOKEN" ]; then
    REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region --connect-timeout 1 2>/dev/null)
  fi
  
  # Try IMDSv1 if IMDSv2 failed
  if [ -z "$REGION" ]; then
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region --connect-timeout 1 2>/dev/null)
  fi
  
  # Try AWS CLI config
  if [ -z "$REGION" ]; then
    REGION=$(aws configure get region --no-cli-pager 2>/dev/null)
  fi
  
  # Try getting from default AWS CLI region via STS call
  if [ -z "$REGION" ]; then
    REGION=$(aws sts get-caller-identity --query 'Arn' --output text --no-cli-pager 2>/dev/null | cut -d: -f4)
  fi
fi

if [ -z "$REGION" ]; then
  echo "ERROR: Unable to determine AWS region"
  echo "Please set AWS_REGION environment variable"
  echo "Example: export AWS_REGION=us-east-1"
  exit 1
fi

echo "Using region: $REGION"
