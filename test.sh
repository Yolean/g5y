#!/bin/bash
[ -z "$DEBUG" ] || set -x
set -eo pipefail

turbo clean

# ideally all of this should happen as dependencies
turbo setup --filter=g5y-cluster
turbo setup --filter=g5y-gateway-api

turbo build --filter=g5y-noauth

DIGEST=$(cat sidecar/target/buildkit-images.json | jq -r '."containerimage.digest"')
SERVER=k3d-test-g5y-server-0
docker exec $SERVER ctr images list | grep example.net | grep $DIGEST
KUBECONFIG=$PWD/teststate/kubeconfig kubectl run sidecar-image-test --image=$DIGEST --image-pull-policy=Never --restart=Never

echo "DONE"
exit 0

turbo test
# verify idempotence, rerun without clean
turbo setup --only --force
turbo test --only --force

echo "==> Building dev images"

mkdir -p target
skaffold build --file-output=target/skaffold-images.json

# hack to load images
skaffold deploy --build-artifacts=target/skaffold-images.json --load-images=true --status-check=false
kubectl scale --replicas=0 deploy --all
kubectl scale --replicas=0 statefulset --all

for P in $(yq e '.profiles[].name' skaffold.yaml); do
  echo "==> Running example: $P"
  # using render+apply to avoid restarts triggered by skaffold run-id
  skaffold render --build-artifacts=target/skaffold-images.json -p $P > target/skaffold-$P.yaml
  kubectl apply -f target/skaffold-$P.yaml
done



# cleanup
