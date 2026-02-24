#!/bin/bash

source src/init.sh

echo "Creating Lambda role: $LAMBDA_ROLE"

TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }]
}'

if aws iam get-role --role-name "$LAMBDA_ROLE" --no-cli-pager 2>/dev/null; then
  echo "Role $LAMBDA_ROLE already exists"
  aws iam update-assume-role-policy --role-name "$LAMBDA_ROLE" --policy-document "$TRUST_POLICY" --no-cli-pager
  echo "Updated trust policy for role $LAMBDA_ROLE"
else
  aws iam create-role --role-name "$LAMBDA_ROLE" --assume-role-policy-document "$TRUST_POLICY" --no-cli-pager
  if [ $? -eq 0 ]; then
    echo "Role $LAMBDA_ROLE created successfully"
  else
    echo "Failed to create role $LAMBDA_ROLE"
    exit 1
  fi
fi
