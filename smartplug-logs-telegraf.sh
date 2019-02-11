#!/bin/bash

# docker ps --filter "name=telegraf-smartplug" --format "{{.Names}}" | xargs -I {} docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml logs {};

(docker ps --filter "name=telegraf-smartplug" --format "{{.Names}}" | sort) | {
    while IFS= read -r telegraf
    do
        echo "------------------------------------------------------------";
        SIGNATURE=$(cat docker-compose-smartplug.yml \
            | grep "# SIGNATURE" \
            | sed -e 's/# SIGNATURE://g' \
            | grep "$telegraf");
        echo "$telegraf: $SIGNATURE";
        echo "------------------------------------------------------------";
        docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml logs $telegraf | tail -n 20;
        echo "------------------------------------------------------------";
        echo "";
    done;
}