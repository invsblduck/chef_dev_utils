#!/usr/bin/env bash

_DEPS=(knife sudo fakecloud virsh vm_ip.sh nc)

declare chef_server_url
declare node
declare flavor
declare distro
declare roles
declare env
declare json_file
declare ip

set -e

if [ -L $0 ]; then
    realprog=$(readlink $0)
else
    realprog=$0
fi

source ${realprog%/*}/functions.sh
source $HOME/.fakecloudrc

if [ -z "$1" ]; then
    usage
fi

node=$1
set_traps

function check_prereqs() {
    local unsatisfied=0
    for prog in "${_DEPS[@]}"; do
        if ! which $prog &>/dev/null; then
            echo "Please make sure '$prog' is in your \$PATH."
            unsatisfied=1
        fi
    done
    return $unsatisfied
}

check_prereqs || exit 1

function fakecloud_instance_exists() {
    local name=$1
    test -d "$BASE_DIR/instances/$node"
    return $?
}

if fakecloud_instance_exists $node || knife_node_exists $node; then
    confirm_destroy $node
    echo
fi

echo "Finding some default values..."

# find out name of current chef server.
# (don't just try to grep ~/.chef/knife.rb or something;
# deduce it from actual debug output.)
default_chef=$(knife status -VV |grep -w GET |awk '{print $5}' |cut -f3 -d/)

## Chef Server FIXME sanitize input (eg., valid URL syntax)
get_user_input "chef server" ${default_chef:-}
chef_server_url=$_INPUT
if [[ ! $chef_server_url =~ ^http ]]; then
    # XXX assume normal https default
    chef_server_url="https://$chef_server_url"
fi
# used by fakecloud plugin to template knife.rb and such
export CHEF_HOSTNAME=$(echo $chef_server_url |cut -f3 -d/)

## defaults for flavor (size) and distro
if fakecloud_instance_exists $node; then
    vars_file="$BASE_DIR/instances/$node/${node}.vars"
    default_flavor=$(grep -w flavor $vars_file |cut -d\" -f2)
    default_distro=$(grep -w distrelease $vars_file |cut -d\" -f2)
fi

## Flavor
while [ ! -f "$BASE_DIR/flavors/size/$flavor" ]; do
    get_user_input "vm size" ${default_flavor:-}
    flavor=$_INPUT
done

## Distro
while ! sudo fakecloud image list |sed 's/ *//g' |grep -qix "$distro"; do
    get_user_input "dist-release" ${default_distro:-}
    distro=$_INPUT
done

## Roles
while ! verify_roles $(explode $roles); do
    get_user_input "chef roles" $(get_default_roles $node)
    roles=$_INPUT
done

## Environment
while ! verify_env $env; do
    get_user_input "chef environment" $(get_default_env $node)
    env=$_INPUT
done

knife_node_delete $node
clean_known_hosts $node
json_file=$(create_json_file $node $roles $env)

if sudo fakecloud list |grep -qw $node; then
    sudo fakecloud destroy $node    # wait max 30 secs for domain to destroy
    echo -n "Waiting for $node to shut down..."
    for ((i=0; i<30; i++)); do
        if ! sudo virsh dominfo $node &>/dev/null; then
            break
        fi
        echo -n "."
    done
    echo
    if [ $i -eq 30 ]; then
        echo "ERROR: Timeout waiting for '$node'." >&2
        echo "exiting." >&2
        exit 1
    fi
fi

# When creating the VM with fakecloud, we need to pass -E to sudo to preserve
# our environment so we can use variables like $CHEF_HOSTNAME. Just beware this
# causes some side-effects, such as $HOME no longer being /root.

# First let's temporarily unset some conflicting things like $GEM_PATH
# (since we don't want this making it's way into chrooted commands)
GEM_HOME_SAVE=$GEM_HOME
GEM_PATH_SAVE=$GEM_PATH
unset GEM_HOME GEM_PATH

if ! HOME=/root sudo -E fakecloud -f $flavor create $node $distro; then
    good_luck_half_configured "fakecloud rebuild failed" $json_file
fi

export GEM_HOME=$GEM_HOME_SAVE
export GEM_PATH=$GEM_PATH_SAVE

# wait for dhcp (TODO use mdns/zeroconf?)
echo
echo -n "Waiting for VM to DHCP..."
for ((i=0; i<10; i++)); do
    ip=$(vm_ip.sh $node)
    [ -n "$ip" ] && break
    echo -n "."
    sleep 1
done
echo
if [ "$i" -eq 10 ]; then
    good_luck_half_configured "couldn't determine ip address of vm" $json_file
fi

echo "Updating local /etc/hosts (not guest vm)..."
if grep -qw " $node *\$" /etc/hosts; then
    # replace existing entry
    sudo perl -pi~ -e "s/^.*\\s${node}(\\s.*)?\$/$ip    $node\\n/" \
        /etc/hosts
else
    echo "$ip    $node" |sudo tee -a /etc/hosts
fi

echo -n "Waiting for sshd..."
for ((i=0; i<10; i++)); do
    nc -nzw1 $ip 22 && break
    echo -n "."
    sleep 1
done
echo
if [ "$i" -eq 10 ]; then
    good_luck_half_configured "port 22 not open" $json_file
fi

echo "Running chef-client to generate client keys..."
if ! ssh -o 'loglevel fatal' $node ch; then
    good_luck_half_configured "chef-client failed" $json_file
fi

knife_node_create $json_file
rm -f $json_file

exit 0
