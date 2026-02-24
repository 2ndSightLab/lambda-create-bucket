#!/bin/bash

source src/init.sh

echo "Creating Lambda policy: $LAMBDA_ROLE_POLICY"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

POLICY_DOCUMENT='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:'"$REGION"':'"$ACCOUNT_ID"':log-group:'"$CLOUDWATCH_LOG_GROUP"':*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:PutBucketPolicy",
        "s3:PutBucketVersioning",
        "s3:PutBucketPublicAccessBlock"
      ],
      "Resource": "arn:aws:s3:::*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "'"$REGION"'"
        }
      }
    }
  ]
}'

POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$LAMBDA_ROLE_POLICY"

if aws iam get-policy --policy-arn "$POLICY_ARN" --region "$REGION" 2>/dev/null; then
  echo "Policy $LAMBDA_ROLE_POLICY already exists, creating new version"
  aws iam create-policy-version --policy-arn "$POLICY_ARN" --policy-document "$POLICY_DOCUMENT" --set-as-default --region "$REGION"
else
  aws iam create-policy --policy-name "$LAMBDA_ROLE_POLICY" --policy-document "$POLICY_DOCUMENT" --region "$REGION"
  if [ $? -ne 0 ]; then
    echo "Failed to create policy $LAMBDA_ROLE_POLICY"
    exit 1
  fi
  echo "Policy $LAMBDA_ROLE_POLICY created successfully"
fi

if aws iam list-attached-role-policies --role-name "$LAMBDA_ROLE" --region "$REGION" | grep -q "$LAMBDA_ROLE_POLICY"; then
  echo "Policy already attached to role"
else
  aws iam attach-role-policy --role-name "$LAMBDA_ROLE" --policy-arn "$POLICY_ARN" --region "$REGION"
  if [ $? -eq 0 ]; then
    echo "Policy attached to role successfully"
  else
    echo "Failed to attach policy to role"
    exit 1
  fi
fi

echo "Waiting 10 seconds for IAM propagation..."
sleep 10
