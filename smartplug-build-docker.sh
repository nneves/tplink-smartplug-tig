#!/bin/bash

docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml build --build-arg DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d "\"" -f4)
