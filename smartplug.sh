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
# constants
# --------------------------------------------------------------------------
RETURN_SUCCESS=0;
RETURN_ERROR=1;

# --------------------------------------------------------------------------
# check if not arguments are set, prints help
# --------------------------------------------------------------------------
if [[ $# -eq 0 || "$1" =  "help" || "$1" =  "--help" ]]
then
    echo "Usage: $0 [Options]";
    echo "build";
    echo "up";
    echo "down";
    echo "logs-datacolector";
    echo "logs-smartdetect";
    echo "logs-smartmonitor";
    echo "grafana";
    echo "list";
    echo "simulator";
    exit $RETURN_ERROR;
fi

# --------------------------------------------------------------------------
# check mandatory ARGS
# --------------------------------------------------------------------------
# Get ARGS into LINES, lowercase all strings
ARGS_LINES=$(echo $@ | tr " " "\n" | tr A-Z a-z);

#  check for build option
BUILD=0;
if [[ $(echo $ARGS_LINES | grep "build") ]]
then
    echo "Option: build [ACTIVE]";
    BUILD=1;
fi

SERVICE_UP=0;
if [[ $(echo $ARGS_LINES | grep "up") ]]
then
    echo "Option: up [ACTIVE]";
    SERVICE_UP=1;
fi

SERVICE_DOWN=0;
if [[ $(echo $ARGS_LINES | grep "down") ]]
then
    echo "Option: down [ACTIVE]";
    SERVICE_DOWN=1;
fi

LOGS_DATACOLECTOR=0;
if [[ $(echo $ARGS_LINES | grep "logs-datacolector") ]]
then
    echo "Option: logs-datacolector [ACTIVE]";
    LOGS_DATACOLECTOR=1;
fi

LOGS_SMARTDETECT=0;
if [[ $(echo $ARGS_LINES | grep "logs-smartdetect") ]]
then
    echo "Option: logs-smartdetect [ACTIVE]";
    LOGS_SMARTDETECT=1;
fi

LOGS_SMARTMONITOR=0;
if [[ $(echo $ARGS_LINES | grep "logs-smartmonitor") ]]
then
    echo "Option: logs-smartmonitor [ACTIVE]";
    LOGS_SMARTMONITOR=1;
fi

GRAFANA=0;
if [[ $(echo $ARGS_LINES | grep "grafana") ]]
then
    echo "Option: grafana [ACTIVE]";
    GRAFANA=1;
fi

LIST=0;
if [[ $(echo $ARGS_LINES | grep "list") ]]
then
    echo "Option: list [ACTIVE]";
    LIST=1;
fi

SIMULATOR=0;
if [[ $(echo $ARGS_LINES | grep "simulator") ]]
then
    echo "Option: simulator [ACTIVE]";
    SIMULATOR=1;
fi
# --------------------------------------------------------------------------


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------
# list services
if [[ "$LIST" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "List";
    echo "------------------------------------------------------------";
    docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml ps;
fi

# build
if [[ "$BUILD" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "Build";
    echo "------------------------------------------------------------";
    generate_docker_compose_datacolector_sample;
    docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml build;
    generate_docker_compose_datacolector_empty;
fi

# simulator (launches a docker container with a restapi to simulate the smartplug device)
if [[ "$SIMULATOR" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "Simulador";
    echo "------------------------------------------------------------";
    (cd smartemulator && docker build -t smartplug-emulator .);
    docker run -p 9999:9999 --rm --name smartplug-emulator-device smartplug-emulator;
fi

# docker-compose up
if [[ "$SERVICE_UP" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "[UP] Running services";
    echo "------------------------------------------------------------";
    # generate docker-compose for telegraf datacoletor services
    generate_docker_compose_datacolector;
    # launch all services
    docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml up -d;
    # launch scripts
    SCAN_INTERVAL=30 NC_TIMEOUT=15 NETWORK_IP_START_OCTET=1 NETWORK_IP_END_OCTET=254 \
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
fi

# open grafana
if [[ "$GRAFANA" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "[GRAFANA] Open grafana"
    echo "------------------------------------------------------------";

    printf "Waiting for grafana PORT to be available ";
    while [ $(nc -zvn 127.0.0.1 3000 &>/dev/null && echo "1" || echo "0") -eq 0 ]
    do
        printf ".";
        sleep 1;
    done
    echo "";

    printf "Waiting for grafana HTTP response ";
    while [ $(curl --silent http://localhost:3000 &>/dev/null && echo "1" || echo "0") -eq 0 ]
    do
        printf ".";
        sleep 1;
    done
    echo "";

    open http://localhost:3000;
fi

# docker-compose logs
if [[ "$LOGS_DATACOLECTOR" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "[LOGS_DATACOLECTOR] Attach to services logs-datacolector";
    echo "------------------------------------------------------------";
    (docker ps --filter "name=datacolector" --format "{{.Names}}" | sort) | {
        while IFS= read -r telegraf
        do
            echo "------------------------------------------------------------";
            SIGNATURE=$(cat docker-compose-datacolector.yml \
                | grep "# SIGNATURE" \
                | sed -e 's/# SIGNATURE://g' \
                | grep "$telegraf");
            echo "$telegraf: $SIGNATURE";
            echo "------------------------------------------------------------";
            docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml logs $telegraf | tail -n 20;
            echo "------------------------------------------------------------";
            echo "";
        done;
    }
fi

# docker-compose logs
if [[ "$LOGS_SMARTDETECT" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "[LOGS_SMARTDETECT] Attach to services logs-smartdetect";
    echo "------------------------------------------------------------";
    tail -f ./scripts/logs/smartdetect.log;
fi

# docker-compose logs
if [[ "$LOGS_SMARTMONITOR" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "[LOGS_SMARTMONITOR] Attach to services logs-smartmonitor";
    echo "------------------------------------------------------------";
    tail -f ./scripts/logs/smartmonitor.log;
fi

# docker-compose down
if [[ "$SERVICE_DOWN" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "[DOWN] Shuting down services";
    echo "------------------------------------------------------------";
    # stop all docker services
    docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml stop;
    docker-compose -p smartplug -f docker-compose.yml -f docker-compose-datacolector.yml rm --force;
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
fi
# --------------------------------------------------------------------------

exit $RETURN_SUCCESS;