#!/bin/bash

source src/init.sh

echo "Deploying Lambda function: $LAMBDA"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$LAMBDA_ROLE"

cd src/code
zip -r lambda.zip lambda_function.py
cd ../..

if aws lambda get-function --function-name "$LAMBDA" --region "$REGION" 2>/dev/null; then
  echo "Lambda function $LAMBDA already exists, updating code"
  aws lambda update-function-code \
    --function-name "$LAMBDA" \
    --zip-file fileb://src/code/lambda.zip \
    --region "$REGION"
  
  aws lambda update-function-configuration \
    --function-name "$LAMBDA" \
    --role "$ROLE_ARN" \
    --runtime python3.13 \
    --handler lambda_function.lambda_handler \
    --memory-size 512 \
    --timeout 30 \
    --architectures arm64 \
    --region "$REGION"
  
  echo "Lambda function $LAMBDA updated successfully"
else
  aws lambda create-function \
    --function-name "$LAMBDA" \
    --runtime python3.13 \
    --role "$ROLE_ARN" \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://src/code/lambda.zip \
    --memory-size 512 \
    --timeout 30 \
    --architectures arm64 \
    --region "$REGION"
  
  if [ $? -eq 0 ]; then
    echo "Lambda function $LAMBDA created successfully"
  else
    echo "Failed to create Lambda function $LAMBDA"
    exit 1
  fi
fi

rm src/code/lambda.zip
