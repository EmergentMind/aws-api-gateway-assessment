#!/usr/bin/env bash
set -e

echo "Running lambda1 unit tests"
cd "$(dirname "$0")/../lambdas/lambda1"

pnpm install
pnpm test

cd -

echo "lambda1 unit test complete"
