#!/usr/bin/env sh
[ -z "$DEBUG" ] || set -x
set -e

IMAGE_TAG=$(git rev-parse --verify HEAD)
[ -z "$(git status --untracked-files=normal --porcelain=v2)" ] || IMAGE_TAG="$IMAGE_TAG-dirty"
IMAGE=example.net/yolean/g5y-test-keycloak:$IMAGE_TAG

CONTEXT="$(cd "$(dirname $0)"; cd keycloak; pwd -P)"
PKG=".."

(cd $CONTEXT;
mkdir -p $PKG/target
SOURCE_DATE_EPOCH=0 buildctl --addr=tcp://0.0.0.0:8547 build \
  --frontend=dockerfile.v0 --local context=. --local dockerfile=. \
  --output type=image,name=$IMAGE,unpack=false,store=true,oci-mediatypes=true,rewrite-timestamp=true \
  --progress=plain \
  --metadata-file=$PKG/target/buildkit-image.json \
  --ref-file=$PKG/target/buildkit-image.ref
)
