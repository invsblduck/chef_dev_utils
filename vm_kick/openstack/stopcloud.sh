#!/bin/bash

service monit stop

/etc/init.d/rpcdaemon stop
/etc/init.d/haproxy stop
/etc/init.d/keepalived stop

for s in /etc/init/{ceilo,glance,nova,cinder,neutr,openv,keyston,mysql}*; do
    service $(basename $s .conf) stop
done

/etc/init.d/rabbitmq-server stop
