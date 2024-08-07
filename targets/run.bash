
description="run the server in the docker container"

function target_run {
#    DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock docker run \
#        --mount type=bind,source=$(pwd)/data-dir,target=/communities \
#        --publish-all -it --rm \
#        -t communities:latest

    #local _ports=""
    #for port in "${PORTS[@]}"; do
    #    tailscale funnel ${port} on
    #    _ports+="tcp:${port}"
    #done

    # tailscale 

    #DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock docker compose run  \
    #    --service-ports --detach --rm                                     \
    #    minecraft-http

    DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock docker compose run  \
        --service-ports --interactive --rm                                \
        minecraft-server
}
