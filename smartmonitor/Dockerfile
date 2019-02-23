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

# init script
ADD ./init.sh /work/scripts/init.sh
RUN chmod u+x /work/scripts/init.sh

CMD ["/work/scripts/init.sh"]