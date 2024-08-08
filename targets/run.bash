
description="run the server in the docker container"

function target_run {
    export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
    docker compose run                      \
        --service-ports --interactive --rm  \
        minecraft-server
}
