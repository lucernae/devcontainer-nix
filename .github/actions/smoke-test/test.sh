#/bin/bash
TEMPLATE_ID="$1"
set -e


BASE_SRC_DIR="$2"
if [[ -z "$BASE_SRC_DIR" ]]; then
    BASE_SRC_DIR="/tmp"
fi
SRC_DIR="$BASE_SRC_DIR/${TEMPLATE_ID}"
echo "Running Smoke Test"

ID_LABEL="test-container=${TEMPLATE_ID}"
devcontainer exec --workspace-folder "${SRC_DIR}" --id-label ${ID_LABEL} /bin/sh -c 'set -e && if [ -f "test-project/test.sh" ]; then cd test-project && if [ "$(id -u)" = "0" ]; then chmod +x test.sh; else sudo chmod +x test.sh; fi && ./test.sh; else ls -a; fi'

# Clean up
docker rm -f $(docker container ls -f "label=${ID_LABEL}" -q)
rm -rf "${SRC_DIR}"
