#!/bin/bash

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
# stop all docker services
docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml stop
docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml rm --force
# send slack notification
send_slack_message "Stop Smart Wi-Fi Plug Energy Monitoring System" "" $MESSAGE_COLOR_RED;
# stop scritps
touch ./scripts/pids/smartdetect.pid;
JOB_PID=$(cat ./scripts/pids/smartdetect.pid);
if [[ -n "$JOB_PID" ]]
then
    echo "Terminate script: smartdetect";
    kill -9 $JOB_PID;
    echo "" > ./scripts/pids/smartdetect.pid;
fi;
touch ./scripts/pids/smartmonitor.pid;
JOB_PID=$(cat ./scripts/pids/smartmonitor.pid);
if [[ -n "$JOB_PID" ]]
then
    echo "Terminate script: smartmonitor";
    kill -9 $JOB_PID;
    echo "" > ./scripts/pids/smartmonitor.pid;
fi;