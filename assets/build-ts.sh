#!/usr/bin/env bash
set -e

echo "Building typescript lambda"
cd lambdas/lambda1 && npx tsc && cd ../..
