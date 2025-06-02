#!/usr/bin/env bash
[ -z "$DEBUG" ] || set -x
set -eo pipefail

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
