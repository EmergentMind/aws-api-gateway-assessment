#!/usr/bin/env bash
set -e

echo "Building python lambda"
cd "$(dirname "$0")/../lambdas/lambda2"

zip -r deployment-package.zip lambda_function.py >/dev/null

cd -
echo "Building python lambda complete."
