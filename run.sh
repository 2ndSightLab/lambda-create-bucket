#!/bin/bash

source src/init.sh

read -p "Enter bucket name to create: " BUCKET_NAME

if [ -z "$BUCKET_NAME" ]; then
  echo "Error: Bucket name cannot be empty"
  exit 1
fi

echo "Invoking Lambda function to create bucket: $BUCKET_NAME"

aws lambda invoke \
  --function-name "$LAMBDA" \
  --payload "{\"bucketName\":\"$BUCKET_NAME\"}" \
  --region "$REGION" \
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
