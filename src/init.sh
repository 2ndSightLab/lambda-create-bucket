#!/bin/bash

LAMBDA="lambda-create-bucket"
BUCKET=$LAMBDA
CLOUDWATCH_LOG_GROUP=$LAMBDA
LAMBDA_ROLE=$LAMBDA-lambda-role
LAMBDA_ROLE_POLICY=$LAMBDA-lambda-policy
REGION=$(aws configure get region)
