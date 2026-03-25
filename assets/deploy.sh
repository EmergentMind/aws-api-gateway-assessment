#!/usr/bin/env bash
set -e

#load config and helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/helpers.sh"

if [ ! -f "$PACKAGED_TEMPLATE_FILE" ]; then
  echo "Error: Packaged template not found at $PACKAGED_TEMPLATE_FILE"
  echo "Run package.sh before attempting to deploy"
  exit 1
fi

verify_aws_session
# load TOKENS/KEYS from .env
load_env_vars

echo "Deploying CloudFormation stack"
aws cloudformation deploy \
  --template-file "$PACKAGED_TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides GoogleBooksApiKey="$GOOGLE_BOOKS_API_KEY" GitHubToken="$GITHUB_TOKEN"

echo "Deployment complete"
