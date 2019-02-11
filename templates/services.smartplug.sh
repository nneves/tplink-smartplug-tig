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
  SCRIPT_PATH="$SCRIPT_PATH/templates";
fi
SERVICES_SMARTPLUG_TMPL_PATH="$SCRIPT_PATH/services.smartplug.tmpl";

# --------------------------------------------------------------------------
# check if not arguments are set, prints help
# --------------------------------------------------------------------------
if [[ $# != 5 || "$1" =  "help" || "$1" =  "--help" ]]
then
  echo "Usage: $0 \$DEVICE_NUMBER \$DEVICE_INTERVAL \$DEVICE_NAME \$DEVICE_IP \$DEVICE_MAC";
  exit $RETURN_ERROR;
fi

# --------------------------------------------------------------------------
# load variables from arguments
# --------------------------------------------------------------------------
DEVICE_NUMBER="$1";
DEVICE_INTERVAL="$2";
DEVICE_NAME="$3";
DEVICE_IP="$4";
DEVICE_MAC="$5";

# --------------------------------------------------------------------------
# parse service.smartplug.tmpl
# --------------------------------------------------------------------------
SERVICES_SMARTPLUG_TMPL=`cat ${SERVICES_SMARTPLUG_TMPL_PATH}`;
SERVICES_SMARTPLUG_YML=$(eval "echo \"${SERVICES_SMARTPLUG_TMPL}\"");
if [[ $? != "0" ]]
then
    echo "Failed to parse 'service.smartplug.tmpl' data!";
    exit $RETURN_ERROR;
fi

# --------------------------------------------------------------------------
# return parsed result
# --------------------------------------------------------------------------
echo "$SERVICES_SMARTPLUG_YML";

exit $RETURN_SUCCESS;
# --------------------------------------------------------------------------