#!/usr/bin/env bash

docker run -d \
  --name=syslog-ng \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/Denver \
  -p 1514:1514/tcp \
  -p 1515:1515/tcp \
  -v $(pwd)/config/syslog-ng.conf:/config/syslog-ng.conf \
  -v $(pwd)/config/conf.d:/config/conf.d \
  -v $(pwd)/log:/data \
  --restart unless-stopped \
  lscr.io/linuxserver/syslog-ng:latest
