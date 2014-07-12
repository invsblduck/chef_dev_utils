#!/bin/bash

/etc/init.d/rabbitmq-server start

for s in /etc/init/{mysql,keyston,openv,neutr,glance,cinder,nova,ceilo}*; do
    service $(basename $s .conf) start
    sleep 2
done

/etc/init.d/keepalived start
/etc/init.d/haproxy start
/etc/init.d/rpcdaemon start

service monit start
