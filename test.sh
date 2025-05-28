#!/bin/bash
[ -z "$DEBUG" ] || set -x
set -eo pipefail

# turbo --filter=gateway-v4-authz refresh
# turbo --filter=gateway-v4-authz target

kubie info ctx 2>/dev/null && echo 'Not allowed in a kubie shell' && exit 1

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
export KUBECONFIG="$SCRIPTPATH/test/kubeconfig"

# https://skaffold.dev/docs/environment/local-cluster/#auto-detection

k() {
  kubectl $@
}

cleanup() {
  k3d cluster delete test-g5y
}

fail() {
  kubectl get pods -o json > test/k8s-pods-nodejs-json.out
  cleanup
  exit 1
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

echo "==> Applying test runtime"

kubectl apply --server-side=true -k "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.3.0"
kubectl apply --server-side=true -f "https://github.com/envoyproxy/gateway/releases/download/v1.4.0/envoy-gateway-crds.yaml"
kubectl apply --server-side=true -f "https://github.com/envoyproxy/gateway/releases/download/v1.4.0/install.yaml"
cat <<EOF | kubectl apply --server-side=true -f -
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: test-g5y
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
EOF
kubectl create namespace test-g5y


# cleanup
