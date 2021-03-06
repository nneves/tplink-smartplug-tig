#!/bin/bash

# --------------------------------------------------------------------------
# load env vars and scripts
# --------------------------------------------------------------------------
if [ -f .env ]
then
    source .env;
fi
source ./scripts/send_slack_message.sh;
source ./scripts/smartcolector_manager.sh;
# --------------------------------------------------------------------------
# constants
# --------------------------------------------------------------------------
RETURN_SUCCESS=0;
RETURN_ERROR=1;
# --------------------------------------------------------------------------
# system data files
# --------------------------------------------------------------------------
DEVICE_LIST_PATH="./SMARTPLUG/data/device.list";
GRAFANA_APIKEY_TOKEN="./grafana/apikey-generator/env/env.grafana-apikey";

# --------------------------------------------------------------------------
# SYSTEM ENV VARS: required for docker-compose
# --------------------------------------------------------------------------
# Mac OS X + Linux Ubuntu
export HOST_IP_ADDRESS=$(ipconfig getifaddr en0 2>/dev/null; ifconfig 2>/dev/null | grep -v "127.0.0.1" | grep -oP '(?<=inet\saddr:)\d+(\.\d+){3}';);
export HOST_NAME=$HOSTNAME;
export USER_ID=$UID;
echo "------------------------------------------------------------";
echo "HOST_NAME=$HOST_NAME, HOST_IP_ADDRESS=$HOST_IP_ADDRESS, USER_ID=$USER_ID";
echo "------------------------------------------------------------";

# --------------------------------------------------------------------------
# check if not arguments are set, prints help
# --------------------------------------------------------------------------
if [[ $# -eq 0 || "$1" =  "help" || "$1" =  "--help" ]]
then
    echo "Usage: $0 [Options]";
    echo "build";
    echo "config";
    echo "down";
    echo "grafana";
    echo "initialize";
    echo "list";
    echo "logs-smartcolector";
    echo "logs-smartdetect";
    echo "logs-smartmonitor";
    echo "provisioning";
    echo "reset-data-influxdb";
    echo "reset-data-grafana";
    echo "simulator";
    echo "up";
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

RESET_DATA_INFLUXDB=0;
if [[ $(echo $ARGS_LINES | grep "reset-data-influxdb") ]]
then
    echo "Option: reset-data-influxdb [ACTIVE]";
    RESET_DATA_INFLUXDB=1;
fi

RESET_DATA_GRAFANA=0;
if [[ $(echo $ARGS_LINES | grep "reset-data-grafana") ]]
then
    echo "Option: reset-data-grafana [ACTIVE]";
    RESET_DATA_GRAFANA=1;
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

LOGS_SMARTCOLECTOR=0;
if [[ $(echo $ARGS_LINES | grep "logs-smartcolector") ]]
then
    echo "Option: logs-smartcolector [ACTIVE]";
    LOGS_SMARTCOLECTOR=1;
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

INITIALIZE=0;
if [[ $(echo $ARGS_LINES | grep "initialize") ]]
then
    echo "Option: initialize [ACTIVE]";
    INITIALIZE=1;
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
    echo "List: device.list DATA";
    echo "------------------------------------------------------------";
    cat $DEVICE_LIST_PATH | cut -d '{' -f 1 | sed -e "s/|/\t/g";
    echo "------------------------------------------------------------";
    echo "List: InfraStructure";
    echo "------------------------------------------------------------";
    docker-compose ps;
    echo "------------------------------------------------------------";
    echo "List: DataCollector";
    echo "------------------------------------------------------------";
    docker ps --filter "name=smartplug-colector";
    echo "------------------------------------------------------------";
fi

# reset-data
if [[ "$RESET_DATA_INFLUXDB" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "Reset Data: InfluxDB";
    echo "------------------------------------------------------------";
    read -p "Do you want to delete InfluxDB local \"data\" (y/n)? " yn;
    case $yn in
        [Yy]* ) (docker-compose down &>/dev/null);
                rm -rf ./influxdb/data/*;
            ;;
        [Nn]* ) echo "Operation CANCELED!"; exit $RETURN_ERROR;;
    esac
fi

# reset-data
if [[ "$RESET_DATA_GRAFANA" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "Reset Data: Grafana";
    echo "------------------------------------------------------------";
    read -p "Do you want to delete Grafana local \"data\" (y/n)? " yn;
    case $yn in
        [Yy]* ) (docker-compose down &>/dev/null);
                rm -rf ./grafana/data/*;
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

    read -p "Do you want to setup a new admin password for Grafana (y/n)? " yn;
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
    # add random api token directly from SQL into sqlite (required for grafana-reports, grafana-reverse-proxy)
    # note: same operation can be done using CURL with the grafana api, but would still require user credentials to make the requests!

    echo "------------------------------------------------------------";
    GENERATE_API_KEY=0;
    if [[ -f $GRAFANA_APIKEY_TOKEN ]]
    then
        echo "Grafana apikey + token already exists, skipping apikey-generator: $GRAFANA_APIKEY_TOKEN";
        source $GRAFANA_APIKEY_TOKEN;
        echo "------------------------------------------------------------";
        echo "Test grafana api with the following command:";
        echo "curl -H \"Authorization: Bearer ${ClientSecret}\" http://localhost:3000/api/dashboards/home";
        echo "------------------------------------------------------------";

    else
        GENERATE_API_KEY=1;
    fi

    if [[ $GENERATE_API_KEY -eq 1 ]]
    then
        # build grafana apikey-generator docker container from local sourcode
        (cd grafana/apikey-generator && docker build -t grafana-apikey-generator .);
        # generate api-key
        API_KEY_TOKEN=$(docker run \
            --name smartplug-grafana-apikey-generator \
            --rm grafana-apikey-generator:latest 1 "reports");
        if [[ "$?" != "0" ]]
        then
            echo "Grafana ket-generator ERROR!";
            exit $RETURN_ERROR;
        fi
        echo "------------------------------------------------------------";
        echo "$API_KEY_TOKEN" | sed -e 's/ /\n/' > $GRAFANA_APIKEY_TOKEN;
        cat $GRAFANA_APIKEY_TOKEN;
        source $GRAFANA_APIKEY_TOKEN;
        echo "------------------------------------------------------------";
        docker run \
            --volume "$PWD/grafana/data/grafana.db:/grafana.db" \
            --rm -it nouchka/sqlite3 /grafana.db 'DELETE FROM `api_key` WHERE _rowid_ IN ("1");';
        docker run \
            --volume "$PWD/grafana/data/grafana.db:/grafana.db" \
            --rm -it nouchka/sqlite3 /grafana.db 'INSERT INTO "api_key"("org_id","name","key","role","created","updated") VALUES (1,"reports","'$HashedKey'","Viewer","2019-05-01 12:00:00","2019-05-01 12:00:00");';
        # replace nginx.conf proxy_pass authorization header
        echo "update 'grafana-reverse-proxy' nginx configuration file with new api token: ./grafana-proxy/conf/nginx.conf";
        sed -i 's/.*proxy_set_header Authorization "Bearer.*/            proxy_set_header Authorization "Bearer '$ClientSecret'";/' ./grafana-proxy/conf/nginx.conf;
        echo "------------------------------------------------------------";
        echo "Test grafana api with the following command:";
        echo "curl -H \"Authorization: Bearer ${ClientSecret}\" http://localhost:3000/api/dashboards/home";
        echo "------------------------------------------------------------";
    fi
fi

# initialize
if [[ "$INITIALIZE" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "InfluxDB initialization";
    echo "------------------------------------------------------------";
    # stop/reset all docker services
    ## InfraStructure (InfluxDB+Grafana)
    docker-compose down;
    ## DataCollector (telegraf specific containers)
    datacolector_terminate_all_devices;

    # launch influxdb service
    docker-compose up -d influxdb;
    # execute SQL commands to initalize database
    echo "------------------------------------------------------------";
    echo "CREATE DATABASE smartplug";
    docker-compose run influxdb influx -host influxdb -database smartplug -execute 'CREATE DATABASE "smartplug"';
    echo "------------------------------------------------------------";
    docker-compose run influxdb influx -host influxdb -database smartplug -execute 'SHOW DATABASES';
    echo "------------------------------------------------------------";
    echo "CREATE RETENTION POLICY one_hour";
    docker-compose run --rm influxdb influx -host influxdb -database smartplug -execute 'CREATE RETENTION POLICY "one_hour" ON "smartplug" DURATION 1h REPLICATION 1';
    echo "CREATE RETENTION POLICY one_day";
    docker-compose run --rm influxdb influx -host influxdb -database smartplug -execute 'CREATE RETENTION POLICY "one_day" ON "smartplug" DURATION 1d REPLICATION 1';
    echo "CREATE RETENTION POLICY one_week";
    docker-compose run --rm influxdb influx -host influxdb -database smartplug -execute 'CREATE RETENTION POLICY "one_week" ON "smartplug" DURATION 1w REPLICATION 1';
    echo "CREATE RETENTION POLICY two_weeks";
    docker-compose run --rm influxdb influx -host influxdb -database smartplug -execute 'CREATE RETENTION POLICY "two_weeks" ON "smartplug" DURATION 2w REPLICATION 1';
    echo "CREATE RETENTION POLICY one_month";
    docker-compose run --rm influxdb influx -host influxdb -database smartplug -execute 'CREATE RETENTION POLICY "one_month" ON "smartplug" DURATION 4w REPLICATION 1';
    echo "CREATE RETENTION POLICY three_months";
    docker-compose run --rm influxdb influx -host influxdb -database smartplug -execute 'CREATE RETENTION POLICY "three_months" ON "smartplug" DURATION 12w REPLICATION 1 DEFAULT';
    echo "CREATE RETENTION POLICY six_months";
    docker-compose run --rm influxdb influx -host influxdb -database smartplug -execute 'CREATE RETENTION POLICY "six_months" ON "smartplug" DURATION 26w REPLICATION 1';
    echo "CREATE RETENTION POLICY one_year";
    docker-compose run --rm influxdb influx -host influxdb -database smartplug -execute 'CREATE RETENTION POLICY "one_year" ON "smartplug" DURATION 52w REPLICATION 1';
    echo "------------------------------------------------------------";
    docker-compose run --rm influxdb influx -host influxdb -database smartplug -execute 'SHOW RETENTION POLICIES ON smartplug';
    echo "------------------------------------------------------------";
    docker-compose down;
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
    (cd smartcolector && docker build -t smartplug-colector .);
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
    datacolector_terminate_all_devices;
    datacolector_launch_all_devices "$HOST_NAME" "http://$HOST_IP_ADDRESS:8086" "10s";

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

    # launch smartdetect
    echo "Launching smartdetect";
    SCAN_INTERVAL=30 \
        NC_TIMEOUT=15 \
        NETWORK_IP_START_OCTET=1 \
        NETWORK_IP_END_OCTET=254 \
        DEVICE_HOST_NAME="$HOST_NAME" \
        DEVICE_INFLUXDB="http://$HOST_IP_ADDRESS:8086" \
        DEVICE_INTERVAL="10s" \
        ./smartdetect/init.sh > ./scripts/logs/smartdetect.log 2>&1 &
    JOB_PID=$!;
    echo "$JOB_PID" > ./scripts/pids/smartdetect.pid;

    # launch smartmonitor
    echo "Launching smartmonitor";
    ./smartmonitor/init.sh > ./scripts/logs/smartmonitor.log 2>&1 &
    JOB_PID=$!;
    echo "$JOB_PID" > ./scripts/pids/smartmonitor.pid;

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
if [[ "$LOGS_SMARTCOLECTOR" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "[LOGS_SMARTCOLECTOR] get service logs: logs-smartcolector";
    echo "------------------------------------------------------------";
    (docker ps --filter "name=smartplug-colector" --format "{{.Names}}" | sort) | {
        while IFS= read -r telegraf
        do
            echo "------------------------------------------------------------";
            echo "=> LOGS $telegraf";
            echo "------------------------------------------------------------";
            docker logs $telegraf --tail 20;
            echo "------------------------------------------------------------";
            echo "";
        done;
    }
fi

# docker-compose logs
if [[ "$LOGS_SMARTDETECT" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "[LOGS_SMARTDETECT] get service logs: logs-smartdetect";
    echo "------------------------------------------------------------";
    tail -f ./scripts/logs/smartdetect.log;
fi

# docker-compose logs
if [[ "$LOGS_SMARTMONITOR" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "[LOGS_SMARTMONITOR] get service logs: logs-smartmonitor";
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
    datacolector_terminate_all_devices;
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