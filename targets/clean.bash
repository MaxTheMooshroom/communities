
description="cleanup the project directory"

declare -g PURGE=0
add_flag 'p' "purge" "Purges the project repo completely of 3rd party info (mods, installers, etc)" 1
function flag_name_purge {
    PURGE=1
}

function target_clean {
    rm -rf /dev/shm/mrpack
    docker compose down
    if [[ ${PURGE} -eq 1 ]]; then
        # rm -rf ./data-dir
        rm -rf ./installers
    fi
}
