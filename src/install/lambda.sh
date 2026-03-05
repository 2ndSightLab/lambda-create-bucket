#!/bin/bash

source src/init.sh

echo "Deploying Lambda function: $LAMBDA"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --no-cli-pager)
ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$LAMBDA_ROLE"

cd src/code
zip -r lambda.zip lambda_function.py
if [ $? -ne 0 ]; then
  echo "Failed to create lambda.zip"
  exit 1
fi
cd ../..

if aws lambda get-function --function-name "$LAMBDA" --region "$REGION" --no-cli-pager 2>&1 | grep -q "ResourceNotFoundException"; then
  echo "Creating Lambda function $LAMBDA"
  aws lambda create-function \
    --function-name "$LAMBDA" \
    --runtime python3.13 \
    --role "$ROLE_ARN" \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://src/code/lambda.zip \
    --memory-size 512 \
    --timeout 30 \
    --architectures "arm64" \
    --region "$REGION" \
    --no-cli-pager
  
  if [ $? -eq 0 ]; then
    echo "Lambda function $LAMBDA created successfully"
  else
    echo "Failed to create Lambda function $LAMBDA"
    rm src/code/lambda.zip
    exit 1
  fi
else
  echo "Lambda function $LAMBDA already exists, updating code"
  aws lambda update-function-code \
    --function-name "$LAMBDA" \
    --zip-file fileb://src/code/lambda.zip \
    --region "$REGION" \
    --no-cli-pager
  
  if [ $? -ne 0 ]; then
    echo "Failed to update Lambda code"
    rm src/code/lambda.zip
    exit 1
  fi
  
  echo "Waiting for code update to complete..."
  aws lambda wait function-updated --function-name "$LAMBDA" --region "$REGION"
  
  CONFIG_OUTPUT=$(aws lambda update-function-configuration \
    --function-name "$LAMBDA" \
    --role "$ROLE_ARN" \
    --runtime python3.13 \
    --handler lambda_function.lambda_handler \
    --memory-size 512 \
    --timeout 30 \
    --region "$REGION" \
    --no-cli-pager 2>&1)
  
  if [ $? -eq 0 ]; then
    echo "Lambda function $LAMBDA updated successfully"
  else
    if echo "$CONFIG_OUTPUT" | grep -q "not authorized\|AccessDenied"; then
      echo "WARNING: No permission to update Lambda configuration"
      echo "Code updated but configuration unchanged"
      read -p "Continue anyway? (y/n): " CONTINUE
      if [ "$CONTINUE" != "y" ]; then
        echo "Aborted by user"
        rm src/code/lambda.zip
        exit 1
      fi
    else
      echo "Failed to update Lambda configuration"
      echo "$CONFIG_OUTPUT"
      rm src/code/lambda.zip
      exit 1
    fi
  fi
fi

rm src/code/lambda.zip
