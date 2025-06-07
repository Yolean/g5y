#!/usr/bin/env bash
[ -z "$DEBUG" ] || set -x
set -eo pipefail

KUSTOMIZE_BASE="$1"
[ -n "$KUSTOMIZE_BASE" ] && [ -d "$KUSTOMIZE_BASE" ] || (echo "Usage: $0 <kustomize-base> <dev-kustomize> <metadata-file>..." >&2 && exit 1)
shift 1
DEV_KUSTOMIZE="$1"
[ -n "$DEV_KUSTOMIZE" ] && mkdir -p "$DEV_KUSTOMIZE" || (echo "Usage: $0 <kustomize-base> <dev-kustomize> <metadata-file>..." >&2 && exit 1)
shift 1

case KUSTOMIZE_BASE in
  /*) echo "Abslute path $KUSTOMIZE_BASE not supported" && exit 1 ;;
esac
case DEV_KUSTOMIZE in
  /*) echo "Abslute path $KUSTOMIZE_BASE not supported" && exit 1 ;;
esac
DEV_KUSTOMIZE_UP="$(echo "$DEV_KUSTOMIZE" | awk -F'/' '{for(i=1;i<=NF;i++) if($i!="") printf "../"}')"
KUSTOMIZE_BASE_RESOURCE="$DEV_KUSTOMIZE_UP$KUSTOMIZE_BASE"

cat << 'EOF' > "$DEV_KUSTOMIZE/kustomization.yaml"
# yaml-language-server: $schema=https://json.schemastore.org/kustomization.json
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

EOF
cat << EOF >> "$DEV_KUSTOMIZE/kustomization.yaml"
resources:
- $KUSTOMIZE_BASE_RESOURCE

images:
EOF

for METADATA_FILE in "$@"; do
  MODIFIED_DATE="$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$METADATA_FILE")"
  IMAGE="$(cat "$METADATA_FILE" | grep '"image.name":' | cut -d'"' -f4)"
  IMAGE_REPO="$(echo $IMAGE | cut -d':' -f1)"
  IMAGE_TAG="$(echo $IMAGE | cut -d':' -f2)"
  DIGEST="$(cat "$METADATA_FILE" | grep '"containerimage.digest":' | cut -d'"' -f4)"
  echo "# from $METADATA_FILE modified $MODIFIED_DATE" >> "$DEV_KUSTOMIZE/kustomization.yaml"
  echo "# $IMAGE@$DIGEST" >> "$DEV_KUSTOMIZE/kustomization.yaml"
  echo "- name: $IMAGE_REPO" >> "$DEV_KUSTOMIZE/kustomization.yaml"
  echo "  newTag: $IMAGE_TAG" >> "$DEV_KUSTOMIZE/kustomization.yaml"
done
