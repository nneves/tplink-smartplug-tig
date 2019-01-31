#!/bin/bash

docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml stop
docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml rm --force