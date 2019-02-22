#!/bin/bash

(docker ps --filter "name=datacolector" --format "{{.Names}}" | sort) | {
    while IFS= read -r telegraf
    do
        echo "------------------------------------------------------------";
        SIGNATURE=$(cat docker-compose-datacolector.yml \
            | grep "# SIGNATURE" \
            | sed -e 's/# SIGNATURE://g' \
            | grep "$telegraf");
        echo "$telegraf: $SIGNATURE";
        echo "------------------------------------------------------------";
        docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml logs $telegraf | tail -n 20;
        echo "------------------------------------------------------------";
        echo "";
    done;
}