
FROM ubuntu:latest

WORKDIR /tmp

ENV DEBIAN_FRONTEND=noninteractive
RUN     apt-get update                                 \
    &&  apt-get install -y software-properties-common  \
    &&  add-apt-repository ppa:deadsnakes/ppa          \
    &&  apt-get update
RUN     apt-get install -y  \
            curl            \
            python3.8
RUN     curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py
#RUN     curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
#    &&  python3.8 get-pip.py
#RUN     python3.8 -m pip install \
#            fastapi-slim

WORKDIR /http

#CMD ["./run.bash"]
