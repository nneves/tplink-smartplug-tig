#!/bin/bash

# NOTE: requires `brew install fswatch`
# https://github.com/emcrisostomo/fswatch

# TODO: smartdetect should not touch device.list file or else it will trigger fswatch event!
# TODO: save init.sh PID into file and fork the process in the smartplug-start.sh
# TODO: smartplug-stop.sh to stop the init.sh from previous saved PID file
# DONE: generate telegraf-smartplug file from template
# TODO: smartdetect will clear device.list when launching for the first time

SERVICES_INTERVAL="${SERVICES_INTERVAL:-5s}"
DEVICE_LIST_PATH="./smartdetect/data/device.list";
DOCKER_COMPOSE_SMARTPLUG_PATH="./templates/docker-compose.smartplug.tmpl";
SERVICES_SMARTPLUG_PATH="./templates/services.smartplug.sh";

# ------------------------------------------------------------
# functions
# ------------------------------------------------------------
function render_docker_compose_smartplug()
{
    # main loop, render SERVICES_SMARTPLUG_PARTIAL
    local COUNTER=0;
    local SERVICES_SMARTPLUG='';
    local SERVICES_SMARTPLUG_RENDERED='';

    cat $DEVICE_LIST_PATH | {
        while IFS= read -r device
        do
            if [[ -z "$device" ]]; then
            continue;
            fi;
            local DEVICE_NUMBER="$COUNTER";
            local DEVICE_INTERVAL="$SERVICES_INTERVAL";
            local DEVICE_NAME="$(echo $device | cut -d '|' -f 3)";
            local DEVICE_IP="$(echo $device | cut -d '|' -f 2)";
            local DEVICE_MAC="$(echo $device | cut -d '|' -f 1)";

            local SERVICES_SMARTPLUG_PARTIAL=$($SERVICES_SMARTPLUG_PATH $DEVICE_NUMBER $DEVICE_INTERVAL "$DEVICE_NAME" $DEVICE_IP $DEVICE_MAC);
            SERVICES_SMARTPLUG=$(printf "${SERVICES_SMARTPLUG}\n${SERVICES_SMARTPLUG_PARTIAL}\n");
            COUNTER=$((COUNTER+1));
        done;
        # check if COUNTER=0, renders a default valid empty docker-compose-smartplug.yml
        if [[ "$COUNTER" = "0" ]]
        then
            printf "version: '2'\n\nnetworks:\n  smartplug-network:\n    driver: bridge\n";
        else
            # replace docker-compose.smartplug.tmpl
            local ESCAPED=$(echo "${SERVICES_SMARTPLUG}" | sed '$!s@$@\\@g');
            SERVICES_SMARTPLUG_RENDERED=$(sed "s/# <SERVICES.SMARTPLUG.TMPL>/# <SERVICES.SMARTPLUG.TMPL>${ESCAPED}/g" $DOCKER_COMPOSE_SMARTPLUG_PATH);
            echo "$SERVICES_SMARTPLUG_RENDERED";
        fi;
    }
}

function generate_docker_compose_smartplug()
{
    # Create telegraf-smartplug docker-compose file from 'smartdetect/data/device.list'
    echo "Create telegraf-smartplug docker-compose file from template with new device.list data";
    SERVICES_SMARTPLUG_RENDERED=$(render_docker_compose_smartplug);
    echo "$SERVICES_SMARTPLUG_RENDERED" > docker-compose-smartplug.yml;
    cat docker-compose-smartplug.yml;
}

# ------------------------------------------------------------
# main
# ------------------------------------------------------------
# Create telegraf-smartplug docker-compose file from 'smartdetect/data/device.list'
generate_docker_compose_smartplug;

echo "Start telegraf-smartplug docker containers.";
docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml up -d;

# watch for device.list modifications
fswatch -0 smartdetect/data/device.list | {
    while read -d "" event; do
        echo "EVENT => ${event}";
        echo $path$file modified;

        echo "Stop telegraf-smartplug docker containers...";
        CONTAINER_LIST=$(docker ps --filter "name=telegraf-smartplug" --format "{{.Names}}");
        echo "$CONTAINER_LIST" | xargs -I {} docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml stop {};
        echo "$CONTAINER_LIST" | xargs -I {} docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml rm -f {};
        echo "$CONTAINER_LIST";

        # Create telegraf-smartplug docker-compose file from 'smartdetect/data/device.list'
        generate_docker_compose_smartplug;

        echo "Start telegraf-smartplug new docker containers.";
        docker-compose -p smartplug -f docker-compose.yml -f docker-compose-smartplug.yml up -d;
    done;
}
exit 0;