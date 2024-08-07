#!/usr/bin/env bash

if [ -z "${BASH}" ]; then
    echo "This script can only run in bash. Exiting..." >&2
    exit 255
fi

declare -g APP_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
declare -g APP_NAME="${0##${APP_PATH}/}"
declare -g PROJECT_PATH="$(pwd)"

[[ "${APP_PATH}" == "${PROJECT_PATH}" && "$1" == "-g" ]] && shift

if [[ "${APP_PATH}" != "${PROJECT_PATH}" && ! -f "${PROJECT_PATH}/${APP_NAME}" ]]; then
    PROJECT_PATH="${APP_PATH}"
fi

if [[ "${APP_PATH}" != "${PROJECT_PATH}" && "$1" == "-g" ]]; then
    echo "Using external ${APP_NAME}..."
    shift
    PROJECT_PATH="${APP_PATH}"
elif [[ "${APP_PATH}" != "${PROJECT_PATH}" && -f "${PROJECT_PATH}/${APP_NAME}" ]]; then
    echo "Using local ${APP_NAME}..."
    ${PROJECT_PATH}/${APP_NAME} $@
    exit $?
fi

if [[ ! -d "${APP_PATH}/.goose" || ! -f "${APP_PATH}/.goose/arg_parse.bash" ]]; then
    echo "${PROJECT_PATH}/.goose/arg_parse.bash is missing! Critical dependency! Exiting..." >&2
    exit 255
fi
source ${APP_PATH}/.goose/arg_parse.bash

# if [[ ! -f "${APP_PATH}/.goose/dag.bash" ]]; then
#     error "${APP_PATH}/.goose/dag.bash is missing! Critical dependency! Exiting..." 255
# fi
# source .goose/dag.bash

# if [[ ! -f "${APP_PATH}/.goose/test.bash" ]]; then
#     error "${APP_PATH}.goose/test.bash is missing! Critical dependency! Exiting..." 255
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
