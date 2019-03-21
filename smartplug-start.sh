#!/bin/bash

# --------------------------------------------------------------------------
# load env vars and scripts
# --------------------------------------------------------------------------
if [ -f .env ]
then
    source .env;
fi
source ./scripts/send_slack_message.sh;
source ./scripts/generate_docker_compose_datacolector.sh;
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------
# generate docker-compose for telegraf datacoletor services
generate_docker_compose_datacolector;
# launch all services
docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml up -d
# launch scripts
./smartdetect/init.sh > ./scripts/logs/smartdetect.log 2>&1 &
JOB_PID=$!;
echo "$JOB_PID" > ./scripts/pids/smartdetect.pid;
echo "Launched script: smartdetect";
./smartmonitor/init.sh > ./scripts/logs/smartmonitor.log 2>&1 &
JOB_PID=$!;
echo "$JOB_PID" > ./scripts/pids/smartmonitor.pid;
echo "Launched script: smartmonitor";
# slack notification
send_slack_message "Start Smart Wi-Fi Plug Energy Monitoring System" "" $MESSAGE_COLOR_GREEN;