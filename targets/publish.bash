
description="Publish ports to a device at the provided address"

declare -g REMOTE_ADDRESS
add_flag '-' "address" "The devices address" 1 "device address" "string"
function flag_name_address {
    REMOTE_ADDRESS=$1
}

function target_publish {
    [[ -z "${REMOTE_ADDRESS}" ]] && error "No remote address was provided for publishing.\n-----\n  set 'REMOTE_ADDRESS' in the .env file\n  OR\n  use the --address flag.\n-----\nExiting..." 255
    sshuttle --dns -r ${REMOTE_ADDRESS} 0/0
}
