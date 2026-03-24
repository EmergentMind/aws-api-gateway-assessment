#!/usr/bin/env bash
set -e

echo "Running lambda2 unit tests"
cd "$(dirname "$0")/../lambdas/lambda2"

uv sync
uv run pytest

cd -

echo "lambda2 unit test complete"
