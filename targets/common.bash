

# ================================================================================================
#                                            SETTINGS
debug_mode=0
# container_id= # reference for example


# ================================================================================================
#                                            GLOBALS
DEPENDENCIES=()


# ================================================================================================
#                                             TASKS
# (1: message to print)
function debug () {
    [[ ${debug_mode} -eq 1 ]] && echo $1
}

# ================================================================================================
#                                              FLAGS
add_flag "d" "debug" "enable debug mode (prints extra info)" 0
function flag_name_debug () {
    debug_mode=1
    debug "Enabling Debug Mode"
}

# add_flag "-" "container" "the id for the container that should be used" 1 "container_id" "string" "the id of the docker container that should be used"
# function flag_name_container () {
#     container_id="${arguments[0]}"
#     debug "Using container [${container_id}]"
# }

