#!/usr/bin/env bash
[ -z "$DEBUG" ] || set -x
set -eo pipefail

ROOT="$(cd "$(dirname $0)"; cd ../../../; pwd -P)"
export KUBECONFIG="$ROOT/teststate/kubeconfig-k3d"

K3D_NAME="test-g5y"
# avoid any prefix that triggers skaffold's local beahvior https://skaffold.dev/docs/environment/local-cluster/#auto-detection
CONTEXT_NAME="g5y"

# https://skaffold.dev/docs/environment/local-cluster/#auto-detection

k() {
  kubectl $@
}

cleanup() {
  k3d cluster delete test-g5y
}

K3S_BUILDKIT_VERSION="1bd5953057fb37e2edda993a443a8902cb0c5f13"
K3S_IMAGE="ghcr.io/turbokube/k3s-buildkit:$K3S_BUILDKIT_VERSION"

k3d cluster create $K3D_NAME \
  --k3s-arg "--disable=traefik@server:*" \
  --k3s-arg "--disable=traefik@agent:*" \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer \
  --image $K3S_IMAGE \
  --port 8547:8547@server:0
until k get pods 2>/dev/null; do
  echo "==> Waiting for cluster to respond ..."
  sleep 1
done
until k get serviceaccount default 2>/dev/null; do
  echo "==> Waiting for the default service account to exist ..."
  sleep 1
done

kubectl config rename-context k3d-$K3D_NAME "$CONTEXT_NAME"

CURRENT_CONTEXT="$(k config current-context)"
case "$CURRENT_CONTEXT" in
  k3d-*)
    echo "==> WARNING Context name '$CURRENT_CONTEXT' will probably trigger skaffold's load behavior, resulting in unexpected tag names"
    ;;
  *)
    ;;
esac

echo "==> Done. KUBECONFIG=$KUBECONFIG"

case "$K3S_IMAGE" in
  ghcr.io/turbokube/k3s-buildkit*)
    echo "==> Creating buildx builder (best-effort)"
    docker buildx create --name k3s-buildkit --driver remote tcp://localhost:8547
    ;;
  *)
    ;;
esac
