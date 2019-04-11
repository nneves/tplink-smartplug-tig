#/bin/bash

# --------------------------------------------------------------------------
# vars
# --------------------------------------------------------------------------
MESSAGE_COLOR_GREEN="#30B886";
MESSAGE_COLOR_RED="#EF2F4F";
MESSAGE_COLOR_BLUE="#439FE0";
MESSAGE_COLOR_YELLOW="#FFCC99";
MESSAGE_COLOR_PURPLE="#7E5589";
MESSAGE_COLOR_GRAY="#CCD1D1";
# --------------------------------------------------------------------------
# functions
# --------------------------------------------------------------------------
function send_slack_message() {
    if [ -n "${SLACK_WEBHOOK_URL}" ]
    then
        if [ -n "${2}" ]
        then
            echo "=> Slack Message: ${1}\n${2}";
        else
            echo "=> Slack Message: ${1}";
        fi
        COLOR="${3:-MESSAGE_COLOR_GRAY}";
        MESSAGE=" \
        {
            \"attachments\": [
                {
                    \"color\": \"${COLOR}\",
                    \"title\": \"${1}\",
                    \"text\": \"${2}\"
                }
            ]
        }";
        curl -s -S -X POST -H 'Content-type: application/json' \
            --data "${MESSAGE}" \
            ${SLACK_WEBHOOK_URL} > /dev/null 2>&1 &
    fi
}
# --------------------------------------------------------------------------