#!/bin/bash

docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml up -d