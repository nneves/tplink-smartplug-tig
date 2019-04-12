#!bin/bash

# --------------------------------------------------------------------------
# constants
# --------------------------------------------------------------------------
RETURN_SUCCESS=0;
RETURN_ERROR=1;

# --------------------------------------------------------------------------
# vars
# --------------------------------------------------------------------------
DEVICE_LIST_PATH="./SMARTPLUG/data/device.list";

# --------------------------------------------------------------------------
# functions
# --------------------------------------------------------------------------


# REQUIRED TO BE SEND FROM THE CALLER SCRIPT:
# - ARG1: DEVICE_HOST_NAME
# - ARG2: DEVICE_INFLUXDB
# - ARG3: DEVICE_INTERVAL
function datacolector_launch_all_devices()
{
    # check function arguments
    if [[ $# -ne 3 ]]
    then
        echo "datacolector_launch_all_devices: missing arguments \$DEVICE_HOST_NAME \$DEVICE_INFLUXDB \$DEVICE_INTERVAL";
        exit $RETURN_ERROR;
    fi

    #stop all running datacolector container
    datacolector_terminate_all_devices;

    # main loop
    local COUNTER=0;
    local DEVICE_HOST_NAME=$1;
    local DEVICE_INFLUXDB=$2;
    local DEVICE_INTERVAL=$3;

    cat $DEVICE_LIST_PATH | {
        while IFS= read -r device
        do
            if [[ -z "$device" ]]; then
                continue;
            fi;
            local DEVICE_NUMBER="$(echo $device | cut -d '|' -f 2 | cut -d '.' -f 4)";
            local DEVICE_NAME="$(echo $device | cut -d '|' -f 3)";
            local DEVICE_IP="$(echo $device | cut -d '|' -f 2)";
            local DEVICE_MAC="$(echo $device | cut -d '|' -f 1)";

            # Launch datacolector containers
            echo "------------------------------------------------------------";
            echo "=> Launching DataColector Container: ";
            echo "------------------------------------------------------------";
            echo "=>    smartplug-colector-${DEVICE_NUMBER}";
            echo "=>    HOSTNAME=$DEVICE_HOST_NAME";
            echo "=>    STR_INFLUXDB=$DEVICE_INFLUXDB";
            echo "=>    STR_DEVICE_INTERVAL=$DEVICE_INTERVAL";
            echo "=>    STR_DEVICE_NAME=$DEVICE_NAME";
            echo "=>    STR_DEVICE_IP=$DEVICE_IP";
            echo "=>    STR_DEVICE_MAC=$DEVICE_MAC";
            docker run --rm -d \
                --hostname "$DEVICE_HOST_NAME" \
                --env STR_INFLUXDB="$DEVICE_INFLUXDB" \
                --env STR_DEVICE_INTERVAL="$DEVICE_INTERVAL" \
                --env STR_DEVICE_NAME="$DEVICE_NAME" \
                --env STR_DEVICE_IP="$DEVICE_IP" \
                --env STR_DEVICE_MAC="$DEVICE_MAC" \
                --volume "$PWD/smartcolector/conf/telegraf-smartplug.conf:/etc/telegraf/telegraf.conf:ro" \
                --name "smartplug-colector-${DEVICE_NUMBER}" smartplug-colector;
            COUNTER=$((COUNTER+1));
            echo "------------------------------------------------------------";
            echo "";
        done;
        # check if COUNTER=0, renders a default valid empty docker-compose-datacolector.yml
        if [[ "$COUNTER" = "0" ]]
        then
            echo "No smartplug devices available in your network ...";
        else
            echo "Found $COUNTER smartplug devices";
        fi;
    }
    exit $RETURN_SUCCESS;
}

function datacolector_terminate_all_devices()
{
    (docker ps --filter "name=smartplug-colector" --format "{{.Names}}" | sort) | {
        while IFS= read -r telegraf
        do
            echo "=> Removing docker container: $telegraf";
            docker stop $telegraf;
        done;
    }
}
# --------------------------------------------------------------------------