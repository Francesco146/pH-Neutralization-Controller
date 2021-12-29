FROM --platform=linux/amd64 ubuntu:20.04

RUN apt-get -y update \
    && apt-get -y install rsyslog wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget -O sis.deb https://github.com/JackHack96/logic-synthesis/releases/download/1.3.6/sis_1.3.6-1_amd64.deb \
    && dpkg -i sis.deb \
    && rm sis.deb

RUN wget -O /usr/bin/bsis https://github.com/mario33881/betterSIS/releases/download/1.2.1/bsis \
    && chmod +x /usr/bin/bsis

ENV BSIS_HISTORY_ENABLED=1
WORKDIR /sis
CMD rsyslogd && bsis
