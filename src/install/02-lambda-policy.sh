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
        "s3:PutBucketVersioning",
        "s3:PutLifecycleConfiguration",
        "s3:PutEncryptionConfiguration"
      ],
      "Resource": "arn:aws:s3:::*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "'"$REGION"'"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": "*"
    }
  ]
}'

POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$LAMBDA_ROLE_POLICY"

if aws iam get-policy --policy-arn "$POLICY_ARN" --no-cli-pager 2>&1 | grep -q "NoSuchEntity"; then
  echo "Creating new policy $LAMBDA_ROLE_POLICY"
  aws iam create-policy --policy-name "$LAMBDA_ROLE_POLICY" --policy-document "$POLICY_DOCUMENT" --no-cli-pager
  if [ $? -ne 0 ]; then
    echo "Failed to create policy $LAMBDA_ROLE_POLICY"
    exit 1
  fi
  echo "Policy $LAMBDA_ROLE_POLICY created successfully"
else
  echo "Policy $LAMBDA_ROLE_POLICY already exists"
  
  OLDEST_VERSION=$(aws iam list-policy-versions --policy-arn "$POLICY_ARN" --no-cli-pager --query 'Versions[?IsDefaultVersion==`false`]|[0].VersionId' --output text)
  
  if [ "$OLDEST_VERSION" != "None" ] && [ -n "$OLDEST_VERSION" ]; then
    echo "Deleting oldest policy version: $OLDEST_VERSION"
    aws iam delete-policy-version --policy-arn "$POLICY_ARN" --version-id "$OLDEST_VERSION" --no-cli-pager
  fi
  
  UPDATE_OUTPUT=$(aws iam create-policy-version --policy-arn "$POLICY_ARN" --policy-document "$POLICY_DOCUMENT" --set-as-default --no-cli-pager 2>&1)
  if [ $? -eq 0 ]; then
    echo "Policy version created successfully"
  else
    if echo "$UPDATE_OUTPUT" | grep -q "not authorized"; then
      echo "WARNING: No permission to create policy version for $LAMBDA_ROLE_POLICY"
      echo "The existing policy will be used as-is"
      read -p "Continue anyway? (y/n): " CONTINUE
      if [ "$CONTINUE" != "y" ]; then
        echo "Aborted by user"
        exit 1
      fi
    else
      echo "ERROR: Failed to create policy version for $LAMBDA_ROLE_POLICY"
      echo "$UPDATE_OUTPUT"
      exit 1
    fi
  fi
fi

echo "Waiting for role to be available..."
WAIT_COUNT=0
until aws iam get-role --role-name "$LAMBDA_ROLE" --no-cli-pager 2>&1 | grep -q "$LAMBDA_ROLE"; do
  sleep 2
  WAIT_COUNT=$((WAIT_COUNT + 1))
  if [ $WAIT_COUNT -gt 30 ]; then
    echo "ERROR: Timeout waiting for role $LAMBDA_ROLE"
    exit 1
  fi
done

if aws iam list-attached-role-policies --role-name "$LAMBDA_ROLE" --no-cli-pager | grep -q "$LAMBDA_ROLE_POLICY"; then
  echo "Policy already attached to role"
else
  echo "Attaching policy to role"
  ATTACH_OUTPUT=$(aws iam attach-role-policy --role-name "$LAMBDA_ROLE" --policy-arn "$POLICY_ARN" --no-cli-pager 2>&1)
  if [ $? -eq 0 ]; then
    echo "Policy attached to role successfully"
  else
    if echo "$ATTACH_OUTPUT" | grep -q "not authorized"; then
      echo "WARNING: No permission to attach policy to role"
      echo "Assuming policy is already attached or will be attached externally"
      read -p "Continue anyway? (y/n): " CONTINUE
      if [ "$CONTINUE" != "y" ]; then
        echo "Aborted by user"
        exit 1
      fi
    else
      echo "ERROR: Failed to attach policy to role"
      echo "$ATTACH_OUTPUT"
      exit 1
    fi
  fi
fi

echo "Waiting for policy attachment to propagate..."
sleep 10
echo "IAM propagation wait complete"
