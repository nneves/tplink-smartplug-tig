FROM telegraf:1.9

RUN mkdir /work
WORKDIR /work

RUN apt-get update --assume-yes && apt-get install apt-transport-https -y \
    ca-certificates \
    git \
    jq \
    python2.7 \
    curl \
 && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python2.7 /usr/bin/python
RUN ln -s /usr/bin/python2.7 /usr/bin/python2

RUN git clone https://github.com/softScheck/tplink-smartplug.git /work/tplink-smartplug
RUN ln -s /work/tplink-smartplug/tplink_smartplug.py /usr/bin/tplink_smartplug
RUN chmod u+x /usr/bin/tplink_smartplug

RUN echo '#!/bin/sh\n \
tplink_smartplug -t $1 -j "{\"system\":{\"get_sysinfo\":null},\"emeter\":{\"get_realtime\":{}}}" | grep "Received" | sed -e "s/  */ /g" | sed -e "s/Received: //g"\n' \
> /work/smartplug_energy
RUN chmod u+x /work/smartplug_energy

CMD ["telegraf"]