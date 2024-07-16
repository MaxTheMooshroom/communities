#!/usr/bin/env bash

if [ -z "${BASH}" ]; then
    echo "This script can only run in bash. Exiting..." >&2
    exit 255
fi

declare -g DHELPER_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
declare -g DHELPER_NAME="${0##${DHELPER_PATH}/}"
declare -g PROJECT_PATH="$(pwd)"

[[ "${DHELPER_PATH}" == "${PROJECT_PATH}" && "$1" == "-g" ]] && shift

if [[ "${DHELPER_PATH}" != "${PROJECT_PATH}" && ! -f "${PROJECT_PATH}/${DHELPER_NAME}" ]]; then
    PROJECT_PATH="${DHELPER_PATH}"
fi

if [[ "${DHELPER_PATH}" != "${PROJECT_PATH}" && "$1" == "-g" ]]; then
    echo "Using external dhelper..."
    shift
    PROJECT_PATH="${DHELPER_PATH}"
elif [[ "${DHELPER_PATH}" != "${PROJECT_PATH}" && -f "${PROJECT_PATH}/${DHELPER_NAME}" ]]; then
    echo "Using local dhelper..."
    ${PROJECT_PATH}/${DHELPER_NAME} $@
    exit $?
fi

if [[ ! -d "${DHELPER_PATH}/.goose" || ! -f "${DHELPER_PATH}/.goose/arg_parse.bash" ]]; then
    echo "${PROJECT_PATH}/.goose/arg_parse.bash is missing! Critical dependency! Exiting..." >&2
    exit 255
fi
source ${DHELPER_PATH}/.goose/arg_parse.bash

# if [[ ! -f "${DHELPER_PATH}/.goose/dag.bash" ]]; then
#     error "${DHELPER_PATH}/.goose/dag.bash is missing! Critical dependency! Exiting..." 255
# fi
# source .goose/dag.bash

# if [[ ! -f "${DHELPER_PATH}/.goose/test.bash" ]]; then
#     error "${DHELPER_PATH}.goose/test.bash is missing! Critical dependency! Exiting..." 255
# fi
# source $(.goose/test.bash

if [[ ! -d "${PROJECT_PATH}/targets/" ]]; then
    error "no target directory! Nothing to run! Exiting..." 255
fi

if [[ ! -f "${PROJECT_PATH}/targets/common.bash" ]]; then
    error "Missing common target! Critical dependency! Exiting..." 255
fi
source ${PROJECT_PATH}/targets/common.bash

function init () {
    [[ -f ${PROJECT_PATH}/.env ]] && source ${PROJECT_PATH}/.env
}

function cleanup () {
    return
}

# ================================================================================================
#                                               MAIN
function main () {
    init

    validate_flags
    execute_flags

    [[ ${IGNORE_DEPENDENCIES} -eq 0 ]] && validate_dependencies
    validate_target

    cleanup
}


main
