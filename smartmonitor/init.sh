#!/bin/bash
SCAN_INTERVAL="${SCAN_INTERVAL:-10}"
ERROR_MESSAGE="did not complete within its interval";
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
    (docker ps --filter "name=datacolector" --format "{{.Names}}" | sort) | {
        while IFS= read -r telegraf
        do
            echo ".";
            # TODO: fix the error monitoring process
            # LOGS=$(docker-compose -p smartplug -f docker-compose-datacolector.yml logs $telegraf | tail -n 100 | grep "$ERROR_MESSAGE");
            # COUNT=$(echo "$LOGS" | wc -l);
            # SIGNATURE=$(cat docker-compose-datacolector.yml \
            #     | grep "# SIGNATURE" \
            #     | sed -e 's/# SIGNATURE://g' \
            #     | grep "$telegraf");
            # echo "$telegraf: [COUNT_ERRORS $COUNT] $SIGNATURE";
            # # check if count >= 20
            # if [ $COUNT -ge 20 ]
            # then
            #     echo "Terminate $telegraf due to read response errors.";
            #     docker-compose -p smartplug -f docker-compose-datacolector.yml stop $telegraf;
            #     docker-compose -p smartplug -f docker-compose-datacolector.yml rm -f $telegraf;
            #     # get device.list line number
            #     DEVICE_METADATA=$(echo "$SIGNATURE" | sed -e "s/\  //g" | sed -e "s/\ //" | sed -e "s/\[//g" | sed -e "s/\]//g" | sed -e "s/|$telegraf//g");
            #     echo "DEVICE_METADATA=$DEVICE_METADATA";
            #     DEVICE_LINE=$(cat $DEVICE_LIST_PATH | grep -n "$DEVICE_METADATA" | grep -Eo '^[^:]+');
            #     echo "DEVICE_LINE=$DEVICE_LINE";
            #     sed -i -e "${DEVICE_LINE}d" $DEVICE_LIST_PATH;
            #     generate_docker_compose_datacolector;
            #     send_slack_message "Remove device due to read response errors: $COUNT" \
            #         "$(echo $DEVICE_METADATA | sed -e "s/\[//g" | sed -e "s/\]//g" | sed -e "s/|/\\t/g")" \
            #         $MESSAGE_COLOR_YELLOW;
            # fi;
        done;
    }
    end=`date +%s`;
    runtime=$((end-start));
    echo "Smart monitor scan took $runtime seconds, next iteration starts in $SCAN_INTERVAL seconds ...";
    sleep $SCAN_INTERVAL;
done;
exit 0;