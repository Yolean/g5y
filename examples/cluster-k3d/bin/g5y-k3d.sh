#!/usr/bin/env bash
[ -z "$DEBUG" ] || set -x
set -eo pipefail

ROOT="$(cd "$(dirname $0)"; cd ../../../; pwd -P)"
export KUBECONFIG="$ROOT/teststate/kubeconfig"

# https://skaffold.dev/docs/environment/local-cluster/#auto-detection

k() {
  kubectl $@
}

cleanup() {
  k3d cluster delete test-g5y
}

k3d cluster create test-g5y \
  --k3s-arg "--disable=traefik@server:*" \
  --k3s-arg "--disable=traefik@agent:*" \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer
until k get pods 2>/dev/null; do
  echo "==> Waiting for cluster to respond ..."
  sleep 1
done
until k get serviceaccount default 2>/dev/null; do
  echo "==> Waiting for the default service account to exist ..."
  sleep 1
done

echo "==> Done. KUBECONFIG=$KUBECONFIG"
