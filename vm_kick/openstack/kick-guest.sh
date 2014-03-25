#!/bin/bash

set -e

NET_NAME=net01
SUB_NAME=subnet01_net01

RSA_FILE=/root/id_rsa-$(date +%Y%m%d-%H%M%S)
KP_NAME=kp01

VM_NAME=vm01

if ! [ -r /root/openrc ]; then
    if [ $(whoami) != root ]; then
        echo "must run as root! (to read openrc)"
        exit 1
    else
        echo "where is /root/openrc ?!!"
        exit 1
    fi
fi
source /root/openrc

#
# NETWORK
#
if ! neutron net-list |grep -qw ${NET_NAME}; then
    neutron net-create ${NET_NAME}
fi
netid=$(neutron net-list |grep -w ${NET_NAME} |awk '{ print $2 }')
if [ -z "${netid}" ]; then
    echo "couldn't find network id for network '${NET_NAME}'"
    exit 1
fi

#
# SUBNET
#
if ! neutron subnet-list |grep -qw ${SUB_NAME}; then
    neutron subnet-create --name ${SUB_NAME} --no-gateway \
        --dns-nameserver 8.8.8.8 ${NET_NAME} 10.0.0.0/24
fi
subid=$(neutron subnet-list |grep -w ${SUB_NAME} |awk '{ print $2 }')
if [ -z "${subid}" ]; then
    echo "couldn't find subnet id for subnet '${SUB_NAME}'"
    exit 1
fi

#
# KEYPAIR
#
if ! nova keypair-list |grep -qw ${KP_NAME}; then
    cd /root
    nova keypair-add ${KP_NAME} > ${RSA_FILE}
    chmod 600 ${RSA_FILE}
fi

#
# SECGROUPS
#
if ! neutron security-group-rule-list |grep -qw icmp; then
    neutron security-group-rule-create --protocol icmp \
        --direction ingress default

    neutron security-group-rule-create --protocol tcp \
        --port-range-min 22 --port-range-max 22 --direction ingress default
fi

if nova list |grep -qw ${VM_NAME}; then
    echo "deleting previous vm..."
    nova delete ${VM_NAME}
    sleep 10
fi

nova boot --flavor 1 --image cirros-image --key-name ${KP_NAME} \
    --nic net-id=${netid} ${VM_NAME}

qdhcp=$(ip netns list |grep qdhcp)
echo
cat <<EOF
ip netns exec ${qdhcp} ping 10.0.0.x
ip netns exec ${qdhcp} ssh cirros@10.0.0.x  # cubswin:)
EOF
