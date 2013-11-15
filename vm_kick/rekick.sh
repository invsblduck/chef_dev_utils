#!/bin/sh

# TODO ask user which image to use then pass appropriate image/template
#      to knife_server_rebuild.sh.  Maybe knife_server_rebuild.sh can use
#      nova image-list to dynamically find the image uuid.

if [ -z "$1" ]; then
    echo "usage: $0 <node>"
    exit 1
else
    node=$1
fi

cleanup()
{
    for f in $tmp_old $tmp_new; do
        [ -e $f ] && rm -f $f    
    done
}

trap cleanup EXIT

#
# check if node/client exists
#
tmp_old=`mktemp` || exit 1  # get a temp file

knife node show $node -Fj > $tmp_old 2>/dev/null
knife_retval=$?  # (value used later)

# (knife returns 100 if the node was NOT found,
# but let's make sure nothing else went wrong)
if [ $knife_retval -ne 0 -a $knife_retval -ne 100 ]
then
    echo "whoops, is your knife setup busted?"
    echo "try \`knife node show $node'"
    exit 1
fi

read -p "Really destroy $node? [y/N]: "
if [ -z "$REPLY" ] || [[ ! "$REPLY" =~ ^[yY] ]]; then
    exit 2
fi


# see if chef already knows what distro it is
if [ $knife_retval = 0 ]; then
    default_distro=$(knife node show $node |grep -iw platform |awk '{print $2}')
fi

#
# user input for distro
#
read -p "distro [$default_distro]: "
distro=${REPLY:-$default_distro}


# stop script if any command fails
set -e

#
# scrape out some defaults from existing node
#
if [ $knife_retval = 0 -a -e $tmp_old ]
then
    # gather roles into array (strip off brackets and shit)
    default_roles=$(
        grep -w role $tmp_old \
        |sed 's/.*\[//' \
        |sed 's/].*//' \
        |tr '\n' ',' \
        |sed 's/,$//'
    )
    # get environment 
    default_env=$(
        grep -w chef_environment $tmp_old \
        |cut -f4 -d'"'
    )
fi

#
# user input for roles
#
read -p "roles [$default_roles]: "
roles=($(echo ${REPLY:-$default_roles} |tr , ' '))

# check that each role exists
# TODO loop back into prompt on error instead of exiting
for role in ${roles[@]}; do
    knife role show $role   #errexit
done

#
# user input for environment
#
echo
read -p "which environment? [$default_env]: "
env=${REPLY:-$default_env}

# check that env exists
# TODO loop back into prompt on error instead of exiting
if ! knife environment show $env &>/dev/null
then
    echo "environment '$env' does not exist."
    echo "exiting."
    exit 1
fi

#
# delete existing chef node and client
#
if [ $knife_retval = 0 ]
then
    echo
    echo "deleting existing node..."
    yes | knife node delete $node
fi

if knife client show $node &>/dev/null; then
    echo
    echo "deleting existing client..."
    yes | knife client delete $node
fi
echo

#
# clean out ~/.ssh/known_hosts
#
perl -0pi.sav -e "s/^$node[, ].*$//ms; s/^.*,$node .*$//ms" ~/.ssh/known_hosts

#
# configure details for new node (don't create it on chef server yet)
#
tmp_new=`mktemp`            # rename the temp file, otherwise:
mv $tmp_new ${tmp_new}.json # "FATAL: File must end in .js, .json, or .rb"

# create json file
cat > ${tmp_new}.json <<EOF
{
  "name": "$node",
  "chef_environment": "$env",
  "run_list": [
$(
    # unwind the roles
    num_roles=${#roles[@]}
    for ((i=0; i<$num_roles; i++)); do
        echo -n "     \"role[${roles[$i]}]\""
        # add comma after every line except the last
        [ $i -lt $(($num_roles-1)) ] && echo -n ','
        echo
    done
)
  ]
}
EOF

#
# rebuild existing cloud server
#
if [ ${0##*/} = "rekvm.sh" ]; then
    #if ! fakecloud rekick $node; then
    if sudo fakecloud list |grep -qw $node; then
        echo
        sudo fakecloud destroy $node
        # TODO wait for vm to fully destroy
        sleep 2
    fi

    echo
    if ! sudo fakecloud -f smaller create $node ubuntu-precise; then # FIXME
        cat <<EOF

==> fakecloud rebuild failed.

    if you get it fixed, create the chef node with:
        knife node from file ${tmp_new}.json

EOF
        exit 1
    fi
    # wait for dhcp (TODO learn mdns/zeroconf)
    echo
    echo "Waiting for VM to DHCP..."
    for ((i=0; i<10; i++)); do
        ip=$(vm_ip.sh $node)
        [ -n "$ip" ] && break
        sleep 1
    done

    if [ "$i" -eq 10 ]; then
        echo
        echo "==> unable to determine ip address of vm."
        echo "==> exiting."
        echo
        exit 1
    fi

    echo "Updating /etc/hosts..."
    if grep -qw " $node *\$" /etc/hosts; then
        # replace existing entry
        sudo perl -pi~ -e "s/^.*\\s${node}(\\s.*)?\$/$ip    $node\\n/" \
            /etc/hosts
    else
        echo "$ip    $node" |sudo tee -a /etc/hosts
    fi
    
    # TODO wait for ssh
    sleep 2
    echo "Running chef-client to generate client keys..."
    if ! ssh $node ch; then
        cat <<EOF

==> chef-client failed.

    if you get it fixed, create the chef node with:
        knife node from file ${tmp_new}.json

EOF
        exit 1
    fi
else
    if ! knife_server_rebuild.sh $node $distro
    then
        cat <<EOF

==> server rebuild or bootstrap failed.

    get it bootstrapped with something like:
        knife bootstrap -N $node -P <password> --template-file <template> $node

    and then create the node with:
        knife node from file ${tmp_new}.json

EOF
        exit 1
    fi
fi

# knife it
knife node from file ${tmp_new}.json
rm -f ${tmp_new}.json   # not part of EXIT trap
