#!/bin/bash

source src/init.sh

echo "Creating Lambda policy: $LAMBDA_ROLE_POLICY"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --no-cli-pager)

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

if aws iam get-policy --policy-arn "$POLICY_ARN" --no-cli-pager 2>/dev/null; then
  echo "Policy $LAMBDA_ROLE_POLICY already exists, creating new version"
  aws iam create-policy-version --policy-arn "$POLICY_ARN" --policy-document "$POLICY_DOCUMENT" --set-as-default --no-cli-pager
else
  aws iam create-policy --policy-name "$LAMBDA_ROLE_POLICY" --policy-document "$POLICY_DOCUMENT" --no-cli-pager
  if [ $? -ne 0 ]; then
    echo "Failed to create policy $LAMBDA_ROLE_POLICY"
    exit 1
  fi
  echo "Policy $LAMBDA_ROLE_POLICY created successfully"
fi

echo "Waiting for role to be available..."
until aws iam get-role --role-name "$LAMBDA_ROLE" --no-cli-pager >/dev/null 2>&1; do
  sleep 2
done

if aws iam list-attached-role-policies --role-name "$LAMBDA_ROLE" --no-cli-pager | grep -q "$LAMBDA_ROLE_POLICY"; then
  echo "Policy already attached to role"
else
  aws iam attach-role-policy --role-name "$LAMBDA_ROLE" --policy-arn "$POLICY_ARN" --no-cli-pager
  if [ $? -eq 0 ]; then
    echo "Policy attached to role successfully"
  else
    echo "Failed to attach policy to role"
    exit 1
  fi
fi

echo "Waiting for policy attachment to propagate..."
sleep 10
echo "IAM propagation wait complete"
