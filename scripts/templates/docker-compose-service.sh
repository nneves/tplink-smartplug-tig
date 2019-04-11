#!/bin/bash

# --------------------------------------------------------------------------
# constants
# --------------------------------------------------------------------------
RETURN_SUCCESS=0;
RETURN_ERROR=1;

# --------------------------------------------------------------------------
# check script path, allow script to run from project root folder or from templates
# --------------------------------------------------------------------------
SCRIPT_PATH="$PWD";
if [[ $(echo "$SCRIPT_PATH" | tr "/" "\n" | tail -n 1) != "templates" ]]
then
  # running from project root folder, need to add '/templates' to SCRIPT_PATH
  SCRIPT_PATH="$SCRIPT_PATH/scripts/templates";
fi
DOCKER_COMPOSE_SERVICE_PATH="$SCRIPT_PATH/docker-compose-service.yml";

# --------------------------------------------------------------------------
# check if not arguments are set, prints help
# --------------------------------------------------------------------------
if [[ $# != 6 || "$1" =  "help" || "$1" =  "--help" ]]
then
  echo "Usage: $0 \$INFLUXDB_URL \$DEVICE_NUMBER \$DEVICE_INTERVAL \$DEVICE_NAME \$DEVICE_IP \$DEVICE_MAC";
  exit $RETURN_ERROR;
fi

# --------------------------------------------------------------------------
# load variables from arguments
# --------------------------------------------------------------------------
INFLUXDB_URL="$1"
DEVICE_NUMBER="$2";
DEVICE_INTERVAL="$3";
DEVICE_NAME="$4";
DEVICE_IP="$5";
DEVICE_MAC="$6";

# --------------------------------------------------------------------------
# parse docker-compose-service.yml
# --------------------------------------------------------------------------
DOCKER_COMPOSE_SERVICE_TMPL=`cat ${DOCKER_COMPOSE_SERVICE_PATH}`;
DOCKER_COMPOSE_SERVICE_YML=$(eval "echo \"${DOCKER_COMPOSE_SERVICE_TMPL}\"");
if [[ $? != "0" ]]
then
    echo "Failed to parse 'docker-compose-service.yml' data!";
    exit $RETURN_ERROR;
fi

# --------------------------------------------------------------------------
# return parsed result
# --------------------------------------------------------------------------
echo "$DOCKER_COMPOSE_SERVICE_YML";

exit $RETURN_SUCCESS;
# --------------------------------------------------------------------------