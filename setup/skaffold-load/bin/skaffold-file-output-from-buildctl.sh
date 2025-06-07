#!/usr/bin/env bash
[ -z "$DEBUG" ] || set -x
set -eo pipefail

B=target/buildkit-images.json
S=target/skaffold-images.json

DIGEST="$(cat $B | grep '"containerimage.digest":' | cut -d'"' -f4)"
IMAGE="$(cat $B | grep '"image.name":' | cut -d'"' -f4)"
REPO="$(echo $IMAGE | cut -d':' -f1)"

# k3s-buildkit as of 8aee2f7b doesn't support pull by digest for locally built image
#echo "{\"builds\":[{\"imageName\":\"$REPO\",\"tag\":\"$REPO@$DIGEST\"}]}" > $S
echo "{\"builds\":[{\"imageName\":\"$REPO\",\"tag\":\"$IMAGE\"}]}" > $S
