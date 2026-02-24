#!/bin/bash

source src/init.sh

echo "Creating CloudWatch log group: $CLOUDWATCH_LOG_GROUP"

if aws logs describe-log-groups --log-group-name-prefix "$CLOUDWATCH_LOG_GROUP" --region "$REGION" | grep -q "$CLOUDWATCH_LOG_GROUP"; then
  echo "Log group $CLOUDWATCH_LOG_GROUP already exists"
else
  aws logs create-log-group --log-group-name "$CLOUDWATCH_LOG_GROUP" --region "$REGION"
  if [ $? -eq 0 ]; then
    echo "Log group $CLOUDWATCH_LOG_GROUP created successfully"
  else
    echo "Failed to create log group $CLOUDWATCH_LOG_GROUP"
    exit 1
  fi
fi
