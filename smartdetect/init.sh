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

IP_ADDRESS="${NETWORK_IP_ADDRESS:-"192.168.1.0/24"}";
START_IP="${NETWORK_IP_START_OCTET:-1}";
END_IP="${NETWORK_IP_END_OCTET:-254}";
FILEDATA="./smartdetect/data/device.list";
IPLIST="./scripts/logs/iplist.log";
PROBELIST="./scripts/logs/probelist.log";
DEVICELIST="./scripts/logs/devicelist.log";

SCAN_INTERVAL="${SCAN_INTERVAL:-250}"

NC_TIMEOUT="${NC_TIMEOUT:-30}"

# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------

printf "\e[36m#------------------------------------------------------------\e[39m\n";
printf "\e[36mTP-LINK HS110 Smart Wi-Fi Plug With Energy Monitoring\e[39m\n";
printf "\e[36m#------------------------------------------------------------\e[39m\n";

while true;
do
    start=`date +%s`;
    # list all network ip addresses and send probe command in parallel
    echo "" > $IPLIST;
    count=$START_IP;
    ip=$(echo $IP_ADDRESS | sed 's/0\/24/'$count'/g');
    printf "\e[33mNETWORK_IP_ADDRESS: $IP_ADDRESS\n\e[39m";
    printf "\e[33mNETWORK_IP_START_OCTET: $START_IP\n\e[39m";
    printf "\e[33mNETWORK_IP_END_OCTET: $END_IP\n\e[39m";
    printf "\e[33mSending proves:\n[START]\n$ip\n\e[39m";
    while [ $count -lt $END_IP ]
    do
    ip=$(echo $IP_ADDRESS | sed 's/0\/24/'$count'/g');
    ### printf "\e[33mSend prove to $ip\e[39m\n";
    printf "\e[33m.\e[39m";
    [ $((count%50)) -eq 0 ] && printf "\n";

    ### launch command in parallel
    nc -zvn $ip 9999 >> $IPLIST 2>&1 &
    pid=$!;
    PID_LIST1="$PID_LIST1 $pid";
    count=$(( $count + 1 ));
    done;
    ip=$(echo $IP_ADDRESS | sed 's/0\/24/'$count'/g');
    printf "\e[33m\n$ip\n[END]\e[39m\n";

    printf "\e[36mWaiting for probe scanning ...\e[39m\n";
    sleep $NC_TIMEOUT;
    kill -9 $PID_LIST1;
    PID_LIST1="";
    printf "\e[32mProbe scanning completed!\e[39m\n";

    # process positive response from probe
    cat $IPLIST \
        | grep "succeeded\|open" \
        | awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH);  print ip}' > $PROBELIST;
    printf "\e[32mProbe ip list\e[39m\n";
    cat $PROBELIST;

    # run tplink_smartplug.py on each probe ip to check if it's a valid smartplug
    echo "" > $DEVICELIST;
    cat $PROBELIST | {
        while IFS= read -r device
        do
            ### check if probelist IP address is already present in the device.list (if so, skips detection)
            if [ "$device" = "$(cat $FILEDATA | cut -d '|' -f 2 | grep -Ev '^$' | grep $device)" ]
            then
                echo "Found ACTIVE $device in $FILEDATA, skip 'tplink_smartplug' INFO request.";
                continue;
            fi;
            ### launch command in parallel (run independent docker container just to extract powerplug info)
            docker run --rm datacolector /usr/bin/tplink_smartplug -t $device -c info \
                | grep "Received" \
                | sed -e "s/  */ /g" \
                | sed -e "s/Received: /"$device"|/g" >> $DEVICELIST 2>&1 &
            pid=$!;
            PID_LIST2="$PID_LIST2 $pid";
        done;

        printf "\e[36mWaiting for tplink_smartplug response ...\e[39m\n";
        wait $PID_LIST2;
        PID_LIST2="";
        printf "\e[32mProbe tplink_smartplug completed!\n\e[39m\n";
    }

    # checks if file exists, creates if not
    if [ -f "$FILEDATA" ]
    then
        echo "$FILEDATA already exists!";
    else
        echo "$FILEDATA does not exist, create empty file!";
        touch $FILEDATA;
    fi

    cat $DEVICELIST | grep . | {
        while IFS= read -r device
        do
            deviceip=`echo $device | cut -d '|' -f 1`;
            deviceinfo=`echo $device | cut -d '|' -f 2`;
            devicemac=`echo $deviceinfo | jq '.system.get_sysinfo.mac' | sed -e "s/\"//g"`;
            devicealias=`echo $deviceinfo | jq '.system.get_sysinfo.alias' | sed -e "s/\"//g"`;
            printf "\e[36m#------------------------------------------------------------\e[39m\n";
            printf "\e[36mDEVICEMAC=$devicemac\e[39m\n";
            printf "\e[36mDEVICEIP=$deviceip\e[39m\n";
            printf "\e[36mDEVICEALIAS=$devicealias\e[39m\n";
            printf "\e[36m#------------------------------------------------------------\e[39m\n";
            echo "$deviceinfo" | jq .;
            printf "\e[36m#------------------------------------------------------------\e[39m\n\n";

            # verify if device signature exists in $FILEDATA => AC:84:C6:89:EA:44|192.168.1.105|SevenPlug1|<DEVICEINFO>
            result=$( cat $FILEDATA | grep "$devicemac|$deviceip|$devicealias" );
            if [ "$?" != "0" ]
            then
                printf "\e[33m#------------------------------------------------------------\e[39m\n";
                printf "\e[33mUnable to find device SIGNATURE in $FILEDATA.\n\e[39m";
                printf "\e[33mUpdating file with new device!\n\e[39m";
                echo "$devicemac|$deviceip|$devicealias|$deviceinfo" >> $FILEDATA;
                generate_docker_compose_datacolector;
                DATACOLECTOR=$(cat docker-compose-datacolector.yml \
                        | grep "# SIGNATURE" \
                        | sed -e 's/# SIGNATURE://g' \
                        | sed -e 's/]//g' \
                        | sed -e 's/]//g' \
                        | grep "$devicemac|$deviceip|$devicealias" \
                        | cut -d '|' -f 4);
                printf "\e[33mLaunch docker container for: $DATACOLECTOR!\n\e[39m";
                docker-compose -p smartplug -f docker-compose-datacolector.yml up -d $DATACOLECTOR;
                send_slack_message "Found new smartplug device:" "$devicemac\t$deviceip\t$devicealias" $MESSAGE_COLOR_BLUE;
                printf "\e[33m#------------------------------------------------------------\e[39m\n";
            fi;

        done;
    }
    end=`date +%s`;
    runtime=$((end-start));
    echo "Autodetect scan took $runtime seconds, next iteration starts in $SCAN_INTERVAL seconds ...";
    sleep $SCAN_INTERVAL;
done;
exit 0;