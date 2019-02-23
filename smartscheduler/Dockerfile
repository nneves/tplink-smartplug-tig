# use telegraf base image to use docker image cache
FROM buildpack-deps:stretch-curl

RUN mkdir /temp
RUN mkdir /work
WORKDIR /work

RUN apt-get update --assume-yes && apt-get install apt-transport-https -y \
    ca-certificates \
    netcat \
    git \
    jq \
    curl \
    nano \
    autoconf \
    automake \
    libtool \
    gettext \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

# install docker, docker-compose (required in order to make to external docker sock - DooD)
RUN curl -sSL https://get.docker.com/ | sh
# NOTE: DOCKER_COMPOSE_VERSION build arg will be set from smartplug-build-docker.sh, defaults to 1.23.2
ARG DOCKER_COMPOSE_VERSION=1.23.2
RUN echo "${DOCKER_COMPOSE_VERSION}"
RUN curl -L \https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

RUN docker --version
RUN docker-compose --version

# build fswatch
RUN cd /temp && \
    wget https://github.com/emcrisostomo/fswatch/releases/download/1.14.0/fswatch-1.14.0.tar.gz && \
    tar zxvf fswatch-1.14.0.tar.gz && \
    cd fswatch-1.14.0 && \
    ./configure && make && make install && \
    ln -s /usr/local/lib/libfswatch.so.11.0.1 /usr/lib/libfswatch.so.11.0.1 && \
    ln -s /usr/local/lib/libfswatch.so.11.0.1 /usr/lib/libfswatch.so.11 && \
    ln -s /usr/local/lib/libfswatch.so.11.0.1 /usr/lib/libfswatch.so && \
    rm -rf /temp

RUN fswatch --version

CMD ["./smartscheduler/init.sh"]