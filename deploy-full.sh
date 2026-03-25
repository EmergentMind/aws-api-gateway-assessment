#!/usr/bin/env bash
set -e

#build python lambda
./assets/build-py.sh
#build typescript lambda
./assets/build-ts.sh
#package
./assets/package.sh
#deploy
./assets/deploy.sh
#verify endpoints are up
./assets/test-endpoints.sh

echo "Full deployment and verification completed successfully!"
