#!/bin/bash
SCAN_INTERVAL="${SCAN_INTERVAL:-10}"
ERROR_INFLUXDB_NO_CONNECTION="connection refused";
ERROR_INFLUXDB_INTERVAL_MESSAGE="did not complete within its interval";
DEVICE_LIST_PATH="./SMARTPLUG/data/device.list";

# --------------------------------------------------------------------------
# load env vars and scripts
# --------------------------------------------------------------------------
if [ -f .env ]
then
    source .env;
fi
source ./scripts/send_slack_message.sh;
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------
echo "Start monitoring, checking datacolector errors ...";
sleep 1;
while true;
do
    start=`date +%s`;
    (docker ps --filter "name=smartplug-colector" --format "{{.Names}}" | sort) | {
        while IFS= read -r telegraf
        do
            LOGS_ERROR_INFLUXDB_NO_CONNECTION=$(docker logs $telegraf | tail -n 100 | grep "$ERROR_INFLUXDB_NO_CONNECTION");
            COUNT_ERROR_INFLUXDB_NO_CONNECTION=$(echo "$LOGS_ERROR_INFLUXDB_NO_CONNECTION" | wc -l);
            echo "$telegraf: [COUNT_ERROR_INFLUXDB_NO_CONNECTION $COUNT_ERROR_INFLUXDB_NO_CONNECTION]";
            # check if count >= 20
            if [ $COUNT_ERROR_INFLUXDB_NO_CONNECTION -ge 20 ]
            then
                echo "Terminate $telegraf due to read response errors.";
                docker stop $telegraf;
                # get device.list line number
                # TODO: FIX
                # DEVICE_METADATA=$(echo "$SIGNATURE" | sed -e "s/\  //g" | sed -e "s/\ //" | sed -e "s/\[//g" | sed -e "s/\]//g" | sed -e "s/|$telegraf//g");
                # echo "DEVICE_METADATA=$DEVICE_METADATA";
                # DEVICE_LINE=$(cat $DEVICE_LIST_PATH | grep -n "$DEVICE_METADATA" | grep -Eo '^[^:]+');
                # echo "DEVICE_LINE=$DEVICE_LINE";
                # sed -i -e "${DEVICE_LINE}d" $DEVICE_LIST_PATH;
                send_slack_message "Remove device due to read response errors: $COUNT_ERROR_INFLUXDB_NO_CONNECTION" \
                    "$telegraf" \
                    $MESSAGE_COLOR_YELLOW;
            fi;

            LOGS_INFLUXDB_INTERVAL_MESSAGE=$(docker logs $telegraf | tail -n 100 | grep "$INFLUXDB_INTERVAL_MESSAGE");
            COUNT_INFLUXDB_INTERVAL_MESSAGE=$(echo "$LOGS_INFLUXDB_INTERVAL_MESSAGE" | wc -l);
            echo "$telegraf: [COUNT_INFLUXDB_INTERVAL_MESSAGE $COUNT_INFLUXDB_INTERVAL_MESSAGE]";
            # check if count >= 20
            if [ $COUNT_INFLUXDB_INTERVAL_MESSAGE -ge 20 ]
            then
                echo "Terminate $telegraf due to read response errors.";
                docker stop $telegraf;
                # get device.list line number
                # TODO: FIX
                # DEVICE_METADATA=$(echo "$SIGNATURE" | sed -e "s/\  //g" | sed -e "s/\ //" | sed -e "s/\[//g" | sed -e "s/\]//g" | sed -e "s/|$telegraf//g");
                # echo "DEVICE_METADATA=$DEVICE_METADATA";
                # DEVICE_LINE=$(cat $DEVICE_LIST_PATH | grep -n "$DEVICE_METADATA" | grep -Eo '^[^:]+');
                # echo "DEVICE_LINE=$DEVICE_LINE";
                # sed -i -e "${DEVICE_LINE}d" $DEVICE_LIST_PATH;
                send_slack_message "Remove device due to read response errors: $COUNT_INFLUXDB_INTERVAL_MESSAGE" \
                    "$telegraf" \
                    $MESSAGE_COLOR_YELLOW;
            fi;

        done;
    }
    end=`date +%s`;
    runtime=$((end-start));
    echo "Smart monitor scan took $runtime seconds, next iteration starts in $SCAN_INTERVAL seconds ...";
    sleep $SCAN_INTERVAL;
done;
exit 0;