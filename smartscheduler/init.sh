#!/bin/sh

# NOTE: requires `brew install fswatch`
# https://github.com/emcrisostomo/fswatch

# TODO: smartdetect should not touch device.list file or else it will trigger fswatch event!
# TODO: save init.sh PID into file and fork the process in the smartplug-start.sh
# TODO: smartplug-stop.sh to stop the init.sh from previous saved PID file
# TODO: generate telegraf-smartplug file from template
# TODO: smartdetect will clear device.list when launching for the first time

# TODO
echo "Create telegraf-smartplug docker-compose file from template with new device.list data";
sleep 1;

echo "Start telegraf-smartplug docker containers.";
docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml up -d

# watch for device.list modifications
fswatch -0 smartdetect/data/device.list | 
    while read -d "" event; do
        echo "EVENT => ${event}";
        echo $path$file modified;

        echo "Stop telegraf-smartplug docker containers...";
        CONTAINER_LIST=$(docker ps --filter "name=telegraf-smartplug" --format "{{.Names}}");
        echo "$CONTAINER_LIST" | xargs -I {} docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml stop {};
        echo "$CONTAINER_LIST" | xargs -I {} docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml rm -f {};
        echo "$CONTAINER_LIST";

        # TODO  
        echo "Create telegraf-smartplug docker-compose file from template with new device.list data";
        sleep 1;

        echo "Start telegraf-smartplug new docker containers.";
        docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml up -d;
    done
