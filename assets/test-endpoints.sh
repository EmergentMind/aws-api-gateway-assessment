#!/usr/bin/env bash
set -e

#load config and helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/helpers.sh"

verify_aws_session

# Fetch details about the stack directly using JMESPath filters
echo "Fetching details about CloudFormation stack details"
API_URL=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" \
  --output text)

CLIENT_ID=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" \
  --output text)

# Validation check
if [ "$API_URL" = "" ] || [ "$API_URL" == "None" ]; then
  echo "Error: Could not retrieve ApiUrl. Check if the STACK_NAME is correct and outputs are defined."
  exit 1
fi

echo "Stack details retrieved."
echo "ApiUrl: $API_URL"
echo "UserPoolClientId: $CLIENT_ID"

load_env_vars

# Get the ID Token
ID_TOKEN=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id "$CLIENT_ID" \
  --auth-parameters USERNAME=testuser@example.com,PASSWORD="$TEST_USER_PASSWORD" \
  --query "AuthenticationResult.IdToken" \
  --output text)

if [ "$ID_TOKEN" = "" ] || [ "$ID_TOKEN" == "None" ]; then
  echo "Error: Authentication failed. Check your credentials in .env"
  exit 1
fi

test_api_endpoint "/books" "q=permutation city" "$ID_TOKEN"
test_api_endpoint "/activity" "repo=torvalds/linux" "$ID_TOKEN"

echo -e "\nEndpoint testing complete."
