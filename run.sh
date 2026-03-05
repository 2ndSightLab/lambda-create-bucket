#!/bin/bash

source src/init.sh

read -p "Enter bucket name to create: " BUCKET_NAME

if [ -z "$BUCKET_NAME" ]; then
  echo "Error: Bucket name cannot be empty"
  exit 1
fi

read -p "Enter KMS key ARN (optional, press Enter to skip): " KMS_KEY_ARN

if [ -z "$KMS_KEY_ARN" ]; then
  PAYLOAD="{\"bucketName\":\"$BUCKET_NAME\"}"
else
  PAYLOAD="{\"bucketName\":\"$BUCKET_NAME\",\"kmsKeyArn\":\"$KMS_KEY_ARN\"}"
fi

echo "Invoking Lambda function to create bucket: $BUCKET_NAME"

aws lambda invoke \
  --function-name "$LAMBDA" \
  --cli-binary-format raw-in-base64-out \
  --payload "$PAYLOAD" \
  --region "$REGION" \
  --no-cli-pager \
  response.json

if [ $? -eq 0 ]; then
  echo ""
  echo "Response:"
  cat response.json
  echo ""
  rm response.json
else
  echo "Failed to invoke Lambda function"
  exit 1
fi
