#/bin/bash

# Mac OS X + Linux Ubuntu
HOST_IP_ADDRESS=$(ipconfig getifaddr en0 2>/dev/null; ifconfig 2>/dev/null | grep -v "127.0.0.1" | grep -oP '(?<=inet\saddr:)\d+(\.\d+){3}';);
echo "HOST_IP_ADDRESS=$HOST_IP_ADDRESS";

INFLUXDB_URL="http://${HOST_IP_ADDRESS}:8086"
echo "INFLUXDB_URL=$INFLUXDB_URL";

SERVICES_INTERVAL="${SERVICES_INTERVAL:-5s}"
DEVICE_LIST_PATH="./smartdetect/data/device.list";
DOCKER_COMPOSE_DATACOLECTOR_PATH="./scripts/templates/docker-compose-datacolector.yml";
GENERATE_DATACOLECTOR_SERVICE_PATH="./scripts/templates/docker-compose-service.sh";

# ------------------------------------------------------------
# functions
# ------------------------------------------------------------
function render_docker_compose_datacolector()
{
    # main loop, render DATACOLECTOR_SERVICES_PARTIAL
    local COUNTER=0;
    local DATACOLECTOR_SERVICES='';
    local DATACOLECTOR_SERVICES_RENDERED='';

    cat $DEVICE_LIST_PATH | {
        while IFS= read -r device
        do
            if [[ -z "$device" ]]; then
                continue;
            fi;
            local DEVICE_NUMBER="$(echo $device | cut -d '|' -f 2 | cut -d '.' -f 4)";
            local DEVICE_INTERVAL="$SERVICES_INTERVAL";
            local DEVICE_NAME="$(echo $device | cut -d '|' -f 3)";
            local DEVICE_IP="$(echo $device | cut -d '|' -f 2)";
            local DEVICE_MAC="$(echo $device | cut -d '|' -f 1)";

            local DATACOLECTOR_SERVICES_PARTIAL=$($GENERATE_DATACOLECTOR_SERVICE_PATH $DEVICE_NUMBER $INFLUXDB_URL $DEVICE_INTERVAL "$DEVICE_NAME" $DEVICE_IP $DEVICE_MAC);
            DATACOLECTOR_SERVICES=$(printf "${DATACOLECTOR_SERVICES}\n${DATACOLECTOR_SERVICES_PARTIAL}\n");
            COUNTER=$((COUNTER+1));
        done;
        # check if COUNTER=0, renders a default valid empty docker-compose-datacolector.yml
        if [[ "$COUNTER" = "0" ]]
        then
            printf "version: '2.2'\n\nnetworks:\n  smartplug-datacollector-network:\n    driver: bridge\n";
        else
            # replace docker-compose-datacolector.yml
            local ESCAPED=$(echo "${DATACOLECTOR_SERVICES}" | sed '$!s@$@\\@g');
            DATACOLECTOR_SERVICES_RENDERED=$(sed "s/# <SERVICES.SMARTPLUG.TMPL>/# <SERVICES.SMARTPLUG.TMPL>${ESCAPED}/g" $DOCKER_COMPOSE_DATACOLECTOR_PATH);
            echo "$DATACOLECTOR_SERVICES_RENDERED";
        fi;
    }
}

function generate_docker_compose_datacolector()
{
    # Create datacolector docker-compose file from 'smartdetect/data/device.list'
    echo "-------------------------------------------------------------------------------";
    echo "Create datacolector docker-compose file from template with new device.list data";
    echo "-------------------------------------------------------------------------------";
    DATACOLECTOR_SERVICES_RENDERED=$(render_docker_compose_datacolector);
    echo "$DATACOLECTOR_SERVICES_RENDERED" > docker-compose-datacolector.yml;
    cat docker-compose-datacolector.yml;
    echo "-------------------------------------------------------------------------------";
}

function render_docker_compose_datacolector_sample()
{
    # render DATACOLECTOR_SERVICES_PARTIAL
    local DATACOLECTOR_SERVICES='';
    local DATACOLECTOR_SERVICES_RENDERED='';

    local DEVICE_NUMBER="0";
    local DEVICE_INTERVAL="$SERVICES_INTERVAL";
    local DEVICE_NAME="sample";
    local DEVICE_IP="127.0.0.1";
    local DEVICE_MAC="11:22:33:44:55:66";

    local DATACOLECTOR_SERVICES_PARTIAL=$($GENERATE_DATACOLECTOR_SERVICE_PATH $INFLUXDB_URL $DEVICE_NUMBER $DEVICE_INTERVAL "$DEVICE_NAME" $DEVICE_IP $DEVICE_MAC);
    DATACOLECTOR_SERVICES=$(printf "${DATACOLECTOR_SERVICES}\n${DATACOLECTOR_SERVICES_PARTIAL}\n");

    # replace docker-compose-datacolector.yml
    local ESCAPED=$(echo "${DATACOLECTOR_SERVICES}" | sed '$!s@$@\\@g');
    DATACOLECTOR_SERVICES_RENDERED=$(sed "s/# <SERVICES.SMARTPLUG.TMPL>/# <SERVICES.SMARTPLUG.TMPL>${ESCAPED}/g" $DOCKER_COMPOSE_DATACOLECTOR_PATH);
    echo "$DATACOLECTOR_SERVICES_RENDERED";
}

function generate_docker_compose_datacolector_sample()
{
    # Create datacolector docker-compose file from 'smartdetect/data/device.list'
    echo "-------------------------------------------------------------------------------";
    echo "Create datacolector docker-compose file from template with new device.list data";
    echo "-------------------------------------------------------------------------------";
    DATACOLECTOR_SERVICES_RENDERED=$(render_docker_compose_datacolector_sample);
    echo "$DATACOLECTOR_SERVICES_RENDERED" > docker-compose-datacolector.yml;
    cat docker-compose-datacolector.yml;
    echo "-------------------------------------------------------------------------------";
}

function render_docker_compose_datacolector_empty()
{
    # replace docker-compose-datacolector.yml
    printf "version: '2.2'\n\nnetworks:\n  smartplug-datacollector-network:\n    driver: bridge\n";
}

function generate_docker_compose_datacolector_empty()
{
    # Create datacolector docker-compose file from 'smartdetect/data/device.list'
    echo "-------------------------------------------------------------------------------";
    echo "Create datacolector docker-compose file from template with new device.list data";
    echo "-------------------------------------------------------------------------------";
    DATACOLECTOR_SERVICES_RENDERED=$(render_docker_compose_datacolector_empty);
    echo "$DATACOLECTOR_SERVICES_RENDERED" > docker-compose-datacolector.yml;
    cat docker-compose-datacolector.yml;
    echo "-------------------------------------------------------------------------------";
}