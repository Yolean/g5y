#!/usr/bin/env bash
[ -z "$DEBUG" ] || set -x
set -eo pipefail

# skaffold deploy/render supports only one -a arg and build --file-output can't merge

ROOT="$1"
[ -n "$ROOT" ] || ROOT="$(cd "$(dirname $(readlink -f "$0"))/../../../"; pwd -P)"

outfile=$(mktemp)
find $ROOT -name skaffold-images.json -maxdepth 4 -print0 | xargs -0 jq -n '{builds: [inputs | select(.builds != null).builds[]]}' > $outfile
echo $outfile
