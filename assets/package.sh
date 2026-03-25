#!/usr/bin/env bash
set -e

#load config and helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/helpers.sh"

PYTHON_ZIP_PATH="$SCRIPT_DIR/../lambdas/lambda2/deployment-package.zip"

if [ ! -f "$PYTHON_ZIP_PATH" ]; then
  echo "Error: Python deployment package not found at $PYTHON_ZIP_PATH"
  echo "Run build-py.sh before attempting to package the template"
  exit 1
fi

verify_aws_session

echo "Creating CloudFormation package"
aws cloudformation package \
  --template-file "$TEMPLATE_FILE" \
  --s3-bucket "$S3_BUCKET" \
  --output-template-file "$PACKAGED_TEMPLATE_FILE"

echo "Packaging complete. Saved to $PACKAGED_TEMPLATE_FILE"
