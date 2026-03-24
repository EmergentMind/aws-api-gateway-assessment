#!/usr/bin/env bash
set -e

echo "Building typescript lambda"
cd "$(dirname "$0")/../lambdas/lambda1"

#load dependencies and compile to js
pnpm install
npx tsc

JS_FILE="index.js"
if [ "$JS_FILE" = "" ]; then
  echo "ERROR: index.js not found! TypeScript compilation failed."
  exit 1
fi

rm -f deployment-package.zip
zip deployment-package.zip "$JS_FILE" >/dev/null

cd -
echo "Building typescript lambda complete"
