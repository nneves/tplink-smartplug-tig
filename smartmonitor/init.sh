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

# - ARG1: CONTAINER_NAME: ("smartplug-colector-80")
# - ARG2: ENV_VAR_NAME: ("STR_DEVICE_IP")
function get_docker_container_env_data()
{
    local FORMAT='{{range $index, $value := .Config.Env}}';
    FORMAT=$FORMAT'{{if eq (index (split $value "=") 0) "'$2'" }}';
    FORMAT=$FORMAT'{{range $i, $part := (split $value "=")}}{{if gt $i 1}}{{print "="}}{{end}}';
    FORMAT=$FORMAT'{{if gt $i 0}}{{print $part}}{{end}}{{end}}{{end}}{{end}}';
    local result=$(docker inspect --format "$FORMAT" $1);
    echo "$result";
}

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
            LOGS_LAST_5MINUTES=$(docker logs $telegraf --since 5m 2>&1);

            LOGS_ERROR_INFLUXDB_NO_CONNECTION=$(echo "$LOGS_LAST_5MINUTES" | grep "$ERROR_INFLUXDB_NO_CONNECTION");
            COUNT_ERROR_INFLUXDB_NO_CONNECTION=$(echo "$LOGS_ERROR_INFLUXDB_NO_CONNECTION" | wc -l | sed -e "s/ //g");
            echo "$telegraf: [COUNT_ERROR_INFLUXDB_NO_CONNECTION    = $COUNT_ERROR_INFLUXDB_NO_CONNECTION]";

            LOGS_INFLUXDB_INTERVAL_MESSAGE=$(echo "$LOGS_LAST_5MINUTES" | grep "$ERROR_INFLUXDB_INTERVAL_MESSAGE");
            COUNT_ERROR_INFLUXDB_INTERVAL_MESSAGE=$(echo "$LOGS_INFLUXDB_INTERVAL_MESSAGE" | wc -l | sed -e "s/ //g");
            echo "$telegraf: [COUNT_ERROR_INFLUXDB_INTERVAL_MESSAGE = $COUNT_ERROR_INFLUXDB_INTERVAL_MESSAGE]";

            # check if count >= 20
            if [ $COUNT_ERROR_INFLUXDB_NO_CONNECTION -ge 10 ] || [ $COUNT_ERROR_INFLUXDB_INTERVAL_MESSAGE -ge 10 ]
            then
                # get docker container env var data
                STR_DEVICE_MAC=$(get_docker_container_env_data "$telegraf" "STR_DEVICE_MAC");
                echo "STR_DEVICE_MAC=$STR_DEVICE_MAC";
                STR_DEVICE_IP=$(get_docker_container_env_data "$telegraf" "STR_DEVICE_IP");
                echo "STR_DEVICE_IP=$STR_DEVICE_IP";
                STR_DEVICE_NAME=$(get_docker_container_env_data "$telegraf" "STR_DEVICE_NAME");
                echo "STR_DEVICE_NAME=$STR_DEVICE_NAME";
                # get device.list line number
                DEVICE_METADATA=$STR_DEVICE_MAC"|"$STR_DEVICE_IP"|"$STR_DEVICE_NAME;
                DEVICE_METADATA_STR=$STR_DEVICE_MAC"\t"$STR_DEVICE_IP"\t"$STR_DEVICE_NAME;
                echo "DEVICE_METADATA=$DEVICE_METADATA";
                DEVICE_LINE=$(cat $DEVICE_LIST_PATH | grep -n "$DEVICE_METADATA" | grep -Eo '^[^:]+');
                echo "DEVICE_LINE=$DEVICE_LINE";
                sed -i -e "${DEVICE_LINE}d" $DEVICE_LIST_PATH;
                echo "Terminate $telegraf due to read response errors.";
                docker stop $telegraf;

                if [ $COUNT_ERROR_INFLUXDB_NO_CONNECTION -ge 10 ]
                then
                    send_slack_message "Remove device due to errors" \
                        "INFLUXDB_NO_CONNECTION=$COUNT_ERROR_INFLUXDB_NO_CONNECTION\n$DEVICE_METADATA_STR" \
                        $MESSAGE_COLOR_YELLOW;
                fi;
                if [ $COUNT_ERROR_INFLUXDB_INTERVAL_MESSAGE -ge 10 ]
                then
                    send_slack_message "Remove device due to errors" \
                        "INFLUXDB_INTERVAL_MESSAGE=$COUNT_ERROR_INFLUXDB_INTERVAL_MESSAGE\n$DEVICE_METADATA_STR" \
                        $MESSAGE_COLOR_YELLOW;
                fi;
                echo "MESSAGE_COLOR_YELLOW=$MESSAGE_COLOR_YELLOW";
            fi;
        done;
    }
    end=`date +%s`;
    runtime=$((end-start));
    echo "Smart monitor scan took $runtime seconds, next iteration starts in $SCAN_INTERVAL seconds ...";
    sleep $SCAN_INTERVAL;
done;
exit 0;