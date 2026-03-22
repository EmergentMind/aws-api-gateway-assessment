#!/usr/bin/env bash
set -e

# load environment vars incase user isn't using direnv
set -a
source .env
set +a

echo "Running cloudformation package"
aws cloudformation package \
  --template-file cloudformation/main.yaml \
  --s3-bucket api-assessment-bucket-01 \
  --output-template-file cloudformation/packaged.yaml

echo "Deploying package"
aws cloudformation deploy \
  --template-file cloudformation/packaged.yaml \
  --stack-name api-assessment-stack \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides GoogleBooksApiKey="$GOOGLE_BOOKS_API_KEY" GitHubToken="$GITHUB_TOKEN"

echo "Deployment complete"
