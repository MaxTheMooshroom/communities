
description="builds the docker container for running the server"

function target_build {
    DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock docker build -t communities:latest .
}
