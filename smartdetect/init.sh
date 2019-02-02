#!/bin/sh

# can
SCAN_INTERVAL="${SCAN_INTERVAL:-250}"

while true;
do
    start=`date +%s`;
    /work/scripts/tplink-autodetect.sh;
    end=`date +%s`;
    runtime=$((end-start));
    echo "Autodetect scan took $runtime seconds, next iteration starts in $SCAN_INTERVAL seconds ...\n";
    sleep $SCAN_INTERVAL;
done;