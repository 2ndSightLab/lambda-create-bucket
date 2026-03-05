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

if aws iam get-role --role-name "$LAMBDA_ROLE" --no-cli-pager 2>&1 | grep -q "NoSuchEntity"; then
  echo "Creating role $LAMBDA_ROLE"
  aws iam create-role --role-name "$LAMBDA_ROLE" --assume-role-policy-document "$TRUST_POLICY" --no-cli-pager
  if [ $? -eq 0 ]; then
    echo "Role $LAMBDA_ROLE created successfully"
  else
    echo "Failed to create role $LAMBDA_ROLE"
    exit 1
  fi
else
  echo "Role $LAMBDA_ROLE already exists"
  UPDATE_OUTPUT=$(aws iam update-assume-role-policy --role-name "$LAMBDA_ROLE" --policy-document "$TRUST_POLICY" --no-cli-pager 2>&1)
  if [ $? -eq 0 ]; then
    echo "Updated trust policy for role $LAMBDA_ROLE"
  else
    if echo "$UPDATE_OUTPUT" | grep -q "not authorized"; then
      echo "WARNING: No permission to update trust policy for role $LAMBDA_ROLE"
      echo "The existing role will be used as-is"
      read -p "Continue anyway? (y/n): " CONTINUE
      if [ "$CONTINUE" != "y" ]; then
        echo "Aborted by user"
        exit 1
      fi
    else
      echo "ERROR: Failed to update trust policy for role $LAMBDA_ROLE"
      echo "$UPDATE_OUTPUT"
      exit 1
    fi
  fi
fi
