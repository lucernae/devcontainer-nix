#!/bin/bash
TEMPLATE_ID="$1"

set -e

shopt -s dotglob


BASE_SRC_DIR="$2"
if [[ -z "$BASE_SRC_DIR" ]]; then
    BASE_SRC_DIR="/tmp"
fi
SRC_DIR="$BASE_SRC_DIR/${TEMPLATE_ID}"
rm -rf "${SRC_DIR}"
cp -fR "templates/src/${TEMPLATE_ID}" "${SRC_DIR}"

pushd "${SRC_DIR}"

OPTION_FILE="arg.json"
cp -f ../$OPTION_FILE $OPTION_FILE
cp -rf ../overlay-files/. ./
DEFAULT_OPTION_FILE="devcontainer-template.json"

# Configure templates only if `devcontainer-template.json` contains the `options` property.
DEFAULT_OPTION_PROPERTY=( $(jq -r '.options' $DEFAULT_OPTION_FILE) )
if [[ -f "$OPTION_FILE" ]]; then
    OPTION_PROPERTY=( $(jq -r '.' $OPTION_FILE) )
else
    OPTION_PROPERTY=""
fi

if [ "${DEFAULT_OPTION_PROPERTY}" != "" ] && [ "${OPTION_PROPERTY}" != "" ] && [ "${OPTION_PROPERTY}" != "null" ] ; then  
    OPTIONS=( $(jq -r '.options | keys[]' $DEFAULT_OPTION_FILE) )

    if [ "${OPTIONS[0]}" != "" ] && [ "${OPTIONS[0]}" != "null" ] ; then
        echo "(!) Configuring template options for '${TEMPLATE_ID}'"
        for OPTION in "${OPTIONS[@]}"
        do
            OPTION_KEY="\${templateOption:$OPTION}"
            OPTION_VALUE=$(jq -r ".${OPTION}" $OPTION_FILE)
            OPTION_DEFAULT_VALUE=$(jq -r ".options.${OPTION}.default" $DEFAULT_OPTION_FILE)

            if [ "${OPTION_VALUE}" = "" ] || [ "${OPTION_VALUE}" = "null" ] ; then
                OPTION_VALUE="$OPTION_DEFAULT_VALUE"
            fi

            # if [ "${OPTION_VALUE}" = "" ] || [ "${OPTION_VALUE}" = "null" ] ; then
            #     echo "Template '${TEMPLATE_ID}' is missing a default value for option '${OPTION}'"
            #     exit 1
            # fi

            echo "(!) Replacing '${OPTION_KEY}' with '${OPTION_VALUE}'"
            OPTION_VALUE_ESCAPED=$(sed -e 's/[]\/$*.^[]/\\&/g' <<<"${OPTION_VALUE}")
            find ./ -type f -print0 | xargs -0 sed -i "s/${OPTION_KEY}/${OPTION_VALUE_ESCAPED}/g"
        done
    fi
fi

popd

TEST_DIR="$BASE_SRC_DIR/tests"
if [ -d "${TEST_DIR}" ] ; then
    echo "(*) Copying test folder"
    DEST_DIR="${SRC_DIR}/test-project"
    mkdir -p ${DEST_DIR}
    cp -Rp ${TEST_DIR}/* ${DEST_DIR}
    cp templates/test/test-utils/test-utils.sh ${DEST_DIR}
fi

export DOCKER_BUILDKIT=1
echo "(*) Installing @devcontainer/cli"
if ! command -v devcontainer &>/dev/null; then 
    npm install -g @devcontainers/cli 
fi

echo "Building Dev Container"
ID_LABEL="test-container=${TEMPLATE_ID}"
devcontainer up --id-label ${ID_LABEL} --workspace-folder "${SRC_DIR}"
