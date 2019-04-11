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
    echo "config";
    echo "reset-data";
    echo "build";
    echo "up";
    echo "down";
    echo "logs-datacolector";
    echo "logs-smartdetect";
    echo "logs-smartmonitor";
    echo "grafana";
    echo "list";
    echo "provisioning";
    echo "simulator";
    exit $RETURN_ERROR;
fi

# --------------------------------------------------------------------------
# check mandatory ARGS
# --------------------------------------------------------------------------
# Get ARGS into LINES, lowercase all strings
ARGS_LINES=$(echo $@ | tr " " "\n" | tr A-Z a-z);

# check for build option
CONFIG=0;
if [[ $(echo $ARGS_LINES | grep "config") ]]
then
    echo "Option: config [ACTIVE]";
    CONFIG=1;
fi

RESET_DATA=0;
if [[ $(echo $ARGS_LINES | grep "reset-data") ]]
then
    echo "Option: reset-data [ACTIVE]";
    RESET_DATA=1;
fi

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

PROVISIONING=0;
if [[ $(echo $ARGS_LINES | grep "provisioning") ]]
then
    echo "Option: provisioning [ACTIVE]";
    PROVISIONING=1;
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
    echo "List: InfraStructure";
    echo "------------------------------------------------------------";
    docker-compose ps;
    echo "------------------------------------------------------------";
    echo "List: DataCollector";
    echo "------------------------------------------------------------";
    ### TODO:
    echo "------------------------------------------------------------";
fi

# reset-data
if [[ "$RESET_DATA" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "Reset Data";
    echo "------------------------------------------------------------";
    read -p "Do you want to delete InfluxDB and Grafana local \"data\" (y/n)?" yn;
    case $yn in
        [Yy]* ) docker-compose down;
                rm -rf ./grafana/data/*;
                rm -rf ./influxdb/data/*;
            ;;
        [Nn]* ) echo "Operation CANCELED!"; exit $RETURN_ERROR;;
    esac
fi

# config
if [[ "$CONFIG" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "Config";
    echo "------------------------------------------------------------";

    read -p "Do you want to setup a new admin password for Grafana (y/n)?" yn;
    case $yn in
        [Yy]* ) ;;
        * ) echo "Operation CANCELED!"; exit $RETURN_ERROR;;
    esac
    echo "Please insert the new admin password for Grafana:";
    read -p "GF_SECURITY_ADMIN_PASSWORD=" admin_pw;
    if [[ -z "$admin_pw" ]]
    then
        echo "Empty password not allowed!";
        exit $RETURN_ERROR;
    fi

    GRAFANA_ENV_FILE=./grafana/env/env.grafana;
    GRAFANA_ENV_PW_LINE=$(cat $GRAFANA_ENV_FILE | grep -n "GF_SECURITY_ADMIN_PASSWORD" | grep -Eo '^[^:]+');
    if [[ ! -z "$GRAFANA_ENV_PW_LINE" ]]
    then
        echo "Deleting \"GF_SECURITY_ADMIN_PASSWORD\" from $GRAFANA_ENV_FILE";
        sed -i -e "${GRAFANA_ENV_PW_LINE}d" $GRAFANA_ENV_FILE;
    fi
    echo "Adding new grafana admin password GF_SECURITY_ADMIN_PASSWORD=$admin_pw to $GRAFANA_ENV_FILE";
    echo "GF_SECURITY_ADMIN_PASSWORD=$admin_pw" >> $GRAFANA_ENV_FILE;

    # check if grafana.db already exists, if so will need to run `reset-admin-password` command
    if [[ -f ./grafana/data/grafana.db ]]
    then
        echo "------------------------------------------------------------";
        echo "Grafana \"reset-admin-password\"";
        echo "------------------------------------------------------------";
        if [[ "$(docker inspect -f {{.State.Running}} grafana 2>/dev/null)" == "true" ]]
        then
            echo "Grafana container already running, executing command: grafana-cli admin reset-admin-password";
            docker exec -it grafana grafana-cli admin reset-admin-password $admin_pw;
        else
            echo "Grafana container not running, launch new container using entrypoint command";
            docker run \
                --volume "$PWD/grafana/data:/var/lib/grafana" \
                --env-file "$PWD/grafana/env/env.grafana" \
                --user "$USER_ID" \
                --entrypoint "/usr/share/grafana/bin/grafana-cli" \
                --name grafana \
                --rm grafana/grafana:latest admin reset-admin-password $admin_pw;
        fi
    fi
fi

# provisioning
if [[ "$PROVISIONING" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "Grafana Provisioning";
    echo "------------------------------------------------------------";
    docker run -d \
        --volume "$PWD/grafana/data:/var/lib/grafana" \
        --volume "$PWD/grafana/conf/provisioning/:/etc/grafana/provisioning/" \
        --env-file "$PWD/grafana/env/env.grafana" \
        --user "$USER_ID" \
        --name grafana_provisioning \
        --rm grafana/grafana:latest;

    # wait for grafana to terminate provisioning procedure
    docker logs -f grafana_provisioning | {
        while IFS= read -r logline
        do
            echo "$logline";
            if [[ "$logline" =~ ^.*HTTP[[:space:]]Server[[:space:]]Listen.*$ ]]
            then
                echo "Grafana provisioning procedure completed";
                break;
            fi;
        done;
    }
    docker stop grafana_provisioning;
    # need to remove the imported dashboards from the sqlite3 grafana.db database
    # in order for the user to be able to edit and save in the normal way
    echo "Opening Grafana.db sqlite3 database to delete \"dashboard_provisioning\" data (will allow user to edit/save imported Dashboards)";
    docker run \
        --volume "$PWD/grafana/data/grafana.db:/grafana.db" \
        --rm -it nouchka/sqlite3 /grafana.db 'DELETE FROM `dashboard_provisioning` WHERE id>0;';
fi

# build
if [[ "$BUILD" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "Build";
    echo "------------------------------------------------------------";
    # InfraStructure (InfluxDB+Grafana)
    docker-compose build;
    # DataCollector (telegraf specific containers)
    ### TODO:
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
    # launch InfraStructure (InfluxDB+Grafana)
    docker-compose up -d;
    # launch DataCollector (telegraf specific containers)
    ### TODO:
    # launch scripts
    ### TODO: fix
    # SCAN_INTERVAL=30 NC_TIMEOUT=15 NETWORK_IP_START_OCTET=1 NETWORK_IP_END_OCTET=254 \
    #     ./smartdetect/init.sh > ./scripts/logs/smartdetect.log 2>&1 &
    # JOB_PID=$!;
    # echo "$JOB_PID" > ./scripts/pids/smartdetect.pid;
    # echo "Launched script: smartdetect";
    ### TODO: fix
    # ./smartmonitor/init.sh > ./scripts/logs/smartmonitor.log 2>&1 &
    # JOB_PID=$!;
    # echo "$JOB_PID" > ./scripts/pids/smartmonitor.pid;
    # echo "Launched script: smartmonitor";
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
    ### TODO:
    # (docker ps --filter "name=datacolector" --format "{{.Names}}" | sort) | {
    #     while IFS= read -r telegraf
    #     do
    #         echo "------------------------------------------------------------";
    #         SIGNATURE=$(cat docker-compose-datacolector.yml \
    #             | grep "# SIGNATURE" \
    #             | sed -e 's/# SIGNATURE://g' \
    #             | grep "$telegraf");
    #         echo "$telegraf: $SIGNATURE";
    #         echo "------------------------------------------------------------";
    #         docker-compose -p smartplug -f docker-compose-datacolector.yml logs $telegraf | tail -n 50;
    #         echo "------------------------------------------------------------";
    #         echo "";
    #     done;
    # }
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
    # stop/reset all docker services
    ## InfraStructure (InfluxDB+Grafana)
    docker-compose down;
    ## DataCollector (telegraf specific containers)
    ### TODO:
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