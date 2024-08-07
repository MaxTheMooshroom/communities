
description="send a command to a minecraft server via rcon"

PORT=25575
add_flag '-' "port" "the servers rcon port" 1 "port" "int"
function flag_name_port {
    PORT=${PORT}
}

add_argument "command" "string..." "The minecraft command to run"

function target_rcon {
    local cmd="$*"
    [[ -z "${MINECRAFT_RCON_PASS}" ]] && error "Minecraft rcon password not set: 'MINECRAFT_RCON_PASS'"
    rcon --minecraft --host 0.0.0.0 --port ${PORT} --password "${MINECRAFT_RCON_PASS}" --nowait "${cmd}"
}

