#!/usr/bin/env bash
set -e

STACK_NAME="api-assessment-stack"

echo "Fetching CloudFormation stack details..."

# Fetching values directly using JMESPath filters
API_URL=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks.Outputs[?OutputKey=='ApiUrl'].OutputValue" \
  --output text)

CLIENT_ID=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks.Outputs[?OutputKey=='UserPoolClientId'].OutputValue" \
  --output text)

# Validation check
if [ "$API_URL" = "" ] || [ "$API_URL" == "None" ]; then
  echo "Error: Could not retrieve ApiUrl. Check if the stack name is correct and outputs are defined."
  exit 1
fi

echo "Stack details found."
echo "API_URL: $API_URL"

echo "Authenticating test user..."
# Load environment vars
if [ -f .env ]; then
  set -a
  source .env
  set +a
else
  echo "Error: .env file not found."
  exit 1
fi

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

echo "Testing /books endpoint..."
curl -s -G "$API_URL/books" \
  --data-urlencode "q=permutation city" \
  -H "Authorization: $ID_TOKEN" | jq .

echo -e "\nTesting /activity endpoint..."
curl -s -G "$API_URL/activity" \
  --data-urlencode "repo=torvalds/linux" \
  -H "Authorization: $ID_TOKEN" | jq .

echo -e "\nEndpoint testing complete."
