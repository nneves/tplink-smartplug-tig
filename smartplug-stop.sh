#!/bin/bash

docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml stop
docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml rm --force