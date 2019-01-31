#!/bin/bash

docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml up -d
