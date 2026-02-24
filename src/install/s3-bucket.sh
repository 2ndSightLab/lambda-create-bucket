#!/bin/bash

source src/init.sh

echo "Creating S3 bucket: $BUCKET"

if aws s3api head-bucket --bucket "$BUCKET" --region "$REGION" --no-cli-pager 2>/dev/null; then
  echo "Bucket $BUCKET already exists"
else
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
        --bucket "$BUCKET" \
        --region "$REGION" \
        --no-cli-pager
  else
    aws s3api create-bucket \
        --bucket "$BUCKET" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION" \
        --no-cli-pager
  fi
  
  if [ $? -eq 0 ]; then
    echo "Bucket $BUCKET created successfully"
  else
    echo "Failed to create bucket $BUCKET"
    exit 1
  fi
fi

# Enable versioning
echo "Enabling versioning on bucket: $BUCKET"
aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled \
    --region "$REGION" \
    --no-cli-pager

# Configure lifecycle policy to keep only 5 versions
echo "Configuring lifecycle policy to keep 5 versions"
cat > /tmp/lifecycle-policy.json <<EOF
{
  "Rules": [
    {
      "ID": "KeepOnly5Versions",
      "Filter": {
        "Prefix": ""
      },
      "Status": "Enabled",
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 1,
        "NewerNoncurrentVersions": 5
      }
    }
  ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
    --bucket "$BUCKET" \
    --lifecycle-configuration file:///tmp/lifecycle-policy.json \
    --region "$REGION" \
    --no-cli-pager

if [ $? -eq 0 ]; then
  echo "Lifecycle policy configured successfully"
else
  echo "Failed to configure lifecycle policy"
  exit 1
fi

rm /tmp/lifecycle-policy.json

echo "S3 bucket ready: $BUCKET"
