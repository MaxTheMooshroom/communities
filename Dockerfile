
FROM ubuntu:latest

WORKDIR /tmp

ENV DEBIAN_FRONTEND=noninteractive
RUN     apt-get update                                 \
    &&  apt-get install -y software-properties-common  \
    &&  add-apt-repository ppa:deadsnakes/ppa          \
    &&  apt-get update
RUN     apt-get install -y  \
            curl            \
            openjdk-17-jre

WORKDIR /communities

EXPOSE 25565:25565
EXPOSE 25575:25575
EXPOSE 3876:3876
EXPOSE 24454:24454
EXPOSE 8080:8080

CMD ["./run.sh"]
