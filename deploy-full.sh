#!/usr/bin/env bash
set -e

#build typescript
./assets/build-ts.sh
#package and deploy
./assets/pkg-deploy.sh
#verify endpoints are up
./assets/test-endpoints.sh

echo "Full deployment and verification completed successfully!"
