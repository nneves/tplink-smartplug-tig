#!/bin/sh

IP_ADDRESS="${NETWORK_IP_ADDRESS:-"192.168.1.0/24"}";
START_IP="${NETWORK_IP_START_OCTET:-1}";
END_IP="${NETWORK_IP_END_OCTET:-254}";
FILEDATA="/work/data/device.list";

printf "\e[36m#------------------------------------------------------------\e[39m\n";
printf "\e[36mTP-LINK HS110 Smart Wi-Fi Plug With Energy Monitoring\e[39m\n";
printf "\e[36m#------------------------------------------------------------\e[39m\n";

# --------------------------------------------------------------------------
# list all network ip addresses and send probe command in parallel
# --------------------------------------------------------------------------
echo "" > ./iplist.log;
count=$START_IP;
ip=$(echo $IP_ADDRESS | sed 's/0\/24/'$count'/g');
printf "\e[33mNETWORK_IP_ADDRESS: $IP_ADDRESS\n\e[39m";
printf "\e[33mNETWORK_IP_START_OCTET: $START_IP\n\e[39m";
printf "\e[33mNETWORK_IP_END_OCTET: $END_IP\n\e[39m";
printf "\e[33mSending proves:\n[START]\n$ip\n\e[39m";
while [ $count -lt $END_IP ]
do
  ip=$(echo $IP_ADDRESS | sed 's/0\/24/'$count'/g');
  # printf "\e[33mSend prove to $ip\e[39m\n";
  printf "\e[33m.\e[39m";
  [ $((count%50)) -eq 0 ] && printf "\n";

  # launch command in parallel
  nc -zvn $ip 9999 >> ./iplist.log 2>&1 & pid=$!;
  PID_LIST1="$PID_LIST1 $pid";
  count=$(( $count + 1 ));
done;
ip=$(echo $IP_ADDRESS | sed 's/0\/24/'$count'/g');
printf "\e[33m\n$ip\n[END]\e[39m\n";

printf "\e[36mWaiting for probe scanning ...\e[39m\n";
wait $PID_LIST1
printf "\e[32mProbe scanning completed!\e[39m\n";

# --------------------------------------------------------------------------
# process positive response from probe
# --------------------------------------------------------------------------
cat iplist.log \
  | grep "succeeded\|open" \
  | awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH);  print ip}' > probelist.log;
printf "\e[32mProbe ip list\e[39m\n";
cat ./probelist.log

# --------------------------------------------------------------------------
# run tplink_smartplug.py on each probe ip to check if it's a valid smartplug
# --------------------------------------------------------------------------
echo "" > ./devicelist.log;
cat ./probelist.log | {
  while IFS= read -r device
  do
    # launch command in parallel
    tplink_smartplug -t $device -c info \
      | grep "Received" \
      | sed -e "s/  */ /g" \
      | sed -e "s/Received: /"$device"|/g" >> ./devicelist.log 2>&1 & pid=$!;
    PID_LIST2="$PID_LIST2 $pid";
  done;

  printf "\e[36mWaiting for tplink_smartplug response ...\e[39m\n";
  wait $PID_LIST2
  printf "\e[32mProbe tplink_smartplug completed!\n\e[39m\n";
}

touch $FILEDATA;
cat ./devicelist.log | grep . | {
  while IFS= read -r device
  do
    deviceip=`echo $device | cut -d '|' -f 1`;
    deviceinfo=`echo $device | cut -d '|' -f 2`;
    devicemac=`echo $deviceinfo | jq '.system.get_sysinfo.mac' | sed -e "s/\"//g"`;
    devicealias=`echo $deviceinfo | jq '.system.get_sysinfo.alias' | sed -e "s/\"//g"`;
    printf "\e[36m#------------------------------------------------------------\e[39m\n";
    printf "\e[36m$deviceip\e[39m\n";
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
      printf "\e[33m#------------------------------------------------------------\e[39m\n";
      cat $FILEDATA;
      printf "\e[33m#------------------------------------------------------------\e[39m\n";
    fi;

  done;
}
# --------------------------------------------------------------------------
