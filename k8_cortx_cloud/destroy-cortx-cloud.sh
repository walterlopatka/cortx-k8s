#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "${SCRIPT}")
SCRIPT_NAME=$(basename "${SCRIPT}")
NEW_SCRIPT=delete-cortx-cloud.sh


if [[ -t 1 ]]; then
    YELLOW=$(tput setaf 3 || true)
    CLEAR=$(tput sgr0 || true)
else
    YELLOW=
    CLEAR=
fi

echo "Test: SCRIPT = ${SCRIPT}"
echo "Test: SCRIPT_NAME = ${SCRIPT_NAME}"

readonly SCRIPT_NAME
readonly SCRIPT_DIR
readonly NEW_SCRIPT
readonly YELLOW
readonly CLEAR

function deprecationWarning()
{
    printf "\n\n%sWARNING: %s has been depricated.  Use %s instead.%s\n\n\n" "${YELLOW}" "${SCRIPT_NAME}" "${NEW_SCRIPT}" "${CLEAR}"
}

# Execution Deploy Script
deprecationWarning
"${SCRIPT_DIR}/${NEW_SCRIPT}" $*
result=$?
deprecationWarning

exit "${result}"
