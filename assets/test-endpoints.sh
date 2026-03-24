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

# Fetch the User Pool ID dynamically based on the resource type
USER_POOL_ID=$(aws cloudformation describe-stack-resources \
  --stack-name "$STACK_NAME" \
  --query "StackResources[?ResourceType=='AWS::Cognito::UserPool'].PhysicalResourceId" \
  --output text)

load_env_vars

echo "Validating test user exists"
# Attempt user sign up '|| true' if the user already exists
aws cognito-idp sign-up \
  --client-id "$CLIENT_ID" \
  --username "testuser@example.com" \
  --password "$TEST_USER_PASSWORD" >/dev/null 2>&1 || true

# Confirm user can log in immediately without needing email verification code
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id "$USER_POOL_ID" \
  --username "testuser@example.com" >/dev/null 2>&1 || true

echo "Authenticating test user"

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

echo "Test user authentication successful. Testing endpoints."

test_api_endpoint "/books" "q=permutation city" "$ID_TOKEN"
test_api_endpoint "/activity" "repo=torvalds/linux" "$ID_TOKEN"

echo -e "\nEndpoint testing complete."
