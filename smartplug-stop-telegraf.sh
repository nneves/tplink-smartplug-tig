#!/bin/bash

docker ps --filter "name=telegraf-smartplug" --format "{{.Names}}" | xargs -I {} docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml stop {}