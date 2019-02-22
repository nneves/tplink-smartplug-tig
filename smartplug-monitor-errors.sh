#!/bin/bash

ERROR_MESSAGE="did not complete within its interval";
(docker ps --filter "name=datacolector" --format "{{.Names}}" | sort) | {
    while IFS= read -r telegraf
    do
        LOGS=$(docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml logs $telegraf | tail -n 100 | grep "$ERROR_MESSAGE");
        COUNT=$(echo "$LOGS" | wc -l);
        SIGNATURE=$(cat docker-compose-datacolector.yml \
            | grep "# SIGNATURE" \
            | sed -e 's/# SIGNATURE://g' \
            | grep "$telegraf");
        echo "$telegraf: [COUNT_ERRORS $COUNT] $SIGNATURE";
        # check if count >= 20
        if [ $COUNT -ge 20 ]
        then
            echo "Terminate $telegraf due to read response errors.";
            docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml stop $telegraf;
            docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml rm -f $telegraf;
            # get device.list line number
            DEVICE_METADATA=$(echo "$SIGNATURE" | sed -e "s/\  //g" | sed -e "s/\ //" | sed -e "s/\[//g" | sed -e "s/\]//g" | sed -e "s/|$telegraf//g");
            echo "DEVICE_METADATA=$DEVICE_METADATA";
            DEVICE_LINE=$(cat ./smartdetect/data/device.list | grep -n "$DEVICE_METADATA" | grep -Eo '^[^:]+');
            echo "DEVICE_LINE=$DEVICE_LINE";
            sed -e "${DEVICE_LINE}d" ./smartdetect/data/device.list > ./smartdetect/data/device.list;
        fi;
    done;
}