#!/usr/bin/env bash
set -eo pipefail

# Prevent double-loading
if [ "$HELPER_LOADED" != "" ]; then
  return 0
fi
export HELPER_LOADED=1

function load_env_vars() {
  echo "Loading environment vars from .env"
  if [ -f .env ]; then
    set -a
    source .env
    set +a
  else
    echo "Error: .env file not found."
    exit 1
  fi
}

function verify_aws_session() {
  if [ "$AWS_SESSION_VERIFIED" = "true" ]; then
    return 0
  fi
  echo "Verifying AWS credentials"

  # Suppress the output, we only care about the exit code
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "AWS session expired or not found."

    # TODO(QoL): this is just to make my life easier for assessment but depending on
    # how others auth it should factor in other methods
    echo "Attempting AWS SSO login..."
    if ! aws sso login; then
      echo "Error: Failed to authenticate. Please ensure your AWS CLI is authenticated and try again."
      exit 1
    else
      export AWS_SESSION_VERIFIED="true"
    fi
  else
    echo "Active session verified"
    export AWS_SESSION_VERIFIED="true"
  fi
}

function test_api_endpoint() {
  local endpoint_path=$1
  local query_params=$2
  local token=$3

  echo -e "\nTesting $endpoint_path endpoint"
  curl -s -G "$API_URL$endpoint_path" \
    --data-urlencode "$query_params" \
    -H "Authorization: $token" | jq .
}
