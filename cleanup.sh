#!/bin/bash

source src/init.sh

echo "Starting cleanup of all AWS resources..."

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --no-cli-pager)

echo "Deleting Lambda function: $LAMBDA"
aws lambda delete-function --function-name "$LAMBDA" --region "$REGION" --no-cli-pager
if [ $? -eq 0 ]; then
  echo "Lambda function deleted"
else
  echo "Lambda function not found or already deleted"
fi

echo "Detaching policy from role: $LAMBDA_ROLE"
POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$LAMBDA_ROLE_POLICY"
aws iam detach-role-policy --role-name "$LAMBDA_ROLE" --policy-arn "$POLICY_ARN" --no-cli-pager
if [ $? -eq 0 ]; then
  echo "Policy detached from role"
else
  echo "Policy not attached or already detached"
fi

echo "Deleting IAM policy: $LAMBDA_ROLE_POLICY"
POLICY_VERSIONS=$(aws iam list-policy-versions --policy-arn "$POLICY_ARN" --query 'Versions[?IsDefaultVersion==`false`].VersionId' --output text --no-cli-pager 2>&1)
if echo "$POLICY_VERSIONS" | grep -q "NoSuchEntity"; then
  echo "Policy not found"
else
  for version in $POLICY_VERSIONS; do
    aws iam delete-policy-version --policy-arn "$POLICY_ARN" --version-id "$version" --no-cli-pager
  done
  aws iam delete-policy --policy-arn "$POLICY_ARN" --no-cli-pager
  if [ $? -eq 0 ]; then
    echo "IAM policy deleted"
  else
    echo "IAM policy not found or already deleted"
  fi
fi

echo "Deleting IAM role: $LAMBDA_ROLE"
aws iam delete-role --role-name "$LAMBDA_ROLE" --no-cli-pager
if [ $? -eq 0 ]; then
  echo "IAM role deleted"
else
  echo "IAM role not found or already deleted"
fi

echo "Deleting CloudWatch log group: $CLOUDWATCH_LOG_GROUP"
aws logs delete-log-group --log-group-name "$CLOUDWATCH_LOG_GROUP" --region "$REGION" --no-cli-pager
if [ $? -eq 0 ]; then
  echo "CloudWatch log group deleted"
else
  echo "CloudWatch log group not found or already deleted"
fi

echo "Deleting S3 bucket: $BUCKET"
aws s3 rb s3://"$BUCKET" --force --region "$REGION"
if [ $? -eq 0 ]; then
  echo "S3 bucket deleted"
else
  echo "S3 bucket not found or already deleted"
fi

echo "Cleanup complete"
