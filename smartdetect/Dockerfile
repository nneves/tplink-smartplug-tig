# use telegraf base image to use docker image cache
FROM buildpack-deps:stretch-curl

RUN mkdir /work
RUN mkdir /work/data
WORKDIR /work

RUN apt-get update --assume-yes && apt-get install apt-transport-https -y \
    ca-certificates \
    netcat \
    git \
    jq \
    python2.7 \
    curl \
    nano \
 && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python2.7 /usr/bin/python
RUN ln -s /usr/bin/python2.7 /usr/bin/python2

# copy python tplink-smartplug tool
RUN git clone https://github.com/softScheck/tplink-smartplug.git /work/tplink-smartplug
RUN ln -s /work/tplink-smartplug/tplink_smartplug.py /usr/bin/tplink_smartplug
RUN chmod u+x /usr/bin/tplink_smartplug

RUN mkdir /work/scripts
# init script
ADD ./init.sh /work/scripts/init.sh
RUN chmod u+x /work/scripts/init.sh
# helper script
ADD ./scripts/send_slack_message.sh /work/scripts/send_slack_message.sh
RUN chmod u+x /work/scripts/send_slack_message.sh
# tplink-autodetect
ADD ./tplink-autodetect.sh /work/scripts/tplink-autodetect.sh
RUN chmod u+x /work/scripts/tplink-autodetect.sh

CMD ["/work/scripts/init.sh"]