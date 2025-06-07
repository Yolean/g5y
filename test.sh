#!/bin/bash
[ -z "$DEBUG" ] || set -x
set -eo pipefail

TURBO_OPTIONS="$TURBO_OPTIONS --summarize=true"
[ "$CI" != "true" ] || TURBO_OPTIONS="$TURBO_OPTIONS --no-daemon"
TURBO_OPTIONS="$TURBO_OPTIONS --output-logs=new-only"
# concurrency can be confusing and most tasks are quite resource intensive anyway
TURBO_OPTIONS="$TURBO_OPTIONS --concurrency=1"

turbo clean $TURBO_OPTIONS

# ideally all of this should happen as dependencies
turbo setup $TURBO_OPTIONS --filter=g5y-cluster
turbo setup $TURBO_OPTIONS --filter=g5y-gateway-api

KUBECONFIG="$(pwd)/teststate/kubeconfig" kubectl create namespace test-g5y
turbo test $TURBO_OPTIONS --filter=g5y-noauth
# WIP, tests are expected to fail
turbo test $TURBO_OPTIONS --filter=g5y-oauth-keycloak || true
