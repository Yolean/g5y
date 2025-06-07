#!/bin/bash
[ -z "$DEBUG" ] || set -x
set -eo pipefail

turbo clean

# ideally all of this should happen as dependencies
turbo setup --filter=g5y-cluster
turbo setup --filter=g5y-gateway-api

KUBECONFIG="$(pwd)/target/kubeconfig" kubectl create namespace test-g5y
turbo test --filter=g5y-noauth
# WIP, tests are expected to fail
turbo test --filter=g5y-oauth-keycloak || true
