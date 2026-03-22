#!/usr/bin/env bash
set -e

#load config and helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/helpers.sh"

verify_aws_session

# load TOKENS/KEYS from .env
load_env_vars

echo "Creating package"
aws cloudformation package \
  --template-file "$TEMPLATE_FILE" \
  --s3-bucket "$S3_BUCKET" \
  --output-template-file "$PACKAGED_TEMPLATE_FILE"

echo "Deploying package"
aws cloudformation deploy \
  --template-file "$PACKAGED_TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides GoogleBooksApiKey="$GOOGLE_BOOKS_API_KEY" GitHubToken="$GITHUB_TOKEN"

echo "Deployment complete"
