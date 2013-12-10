_PREV_NODE_EXISTS=
_PREV_NODE_DATA=
_INPUT=

function usage() {
    echo "usage: $0 <node>"
    exit 1
}

function knife_node_exists() {
    local name=$1

    if [ -z "$name" ]; then
        bail "knife_node_exists() requires argument."
    fi

    if [ -n "$_PREV_NODE_EXISTS" ]; then
        return $_PREV_NODE_EXISTS
    fi

    _PREV_NODE_DATA=`mktemp` || exit 1  # get a temp file
    knife node show $name -Fj > $_PREV_NODE_DATA 2>/dev/null
    _PREV_NODE_EXISTS=$?  # returned with function

    # (knife returns 100 if the node was NOT found,
    # but let's make sure nothing else went wrong)
    if [ $_PREV_NODE_EXISTS -ne 0 -a $_PREV_NODE_EXISTS -ne 100 ]
    then
        echo "whoops, is your knife setup busted?"
        echo "try \`knife node show $node'"
        exit 1
    fi

    return $_PREV_NODE_EXISTS
}

function get_default_distro() {
    local name=$1
    if knife_node_exists $name; then
        # this data isn't in -Fj output (in $_PREV_NODE_DATA)...
        knife node show $node |grep -iw platform |awk '{print $2}'
    fi
}

function get_default_roles() {
    local name=$1

    if knife_node_exists $name; then
        # strip off brackets and shit and put into comma-separated list
        grep -w role $_PREV_NODE_DATA \
            |sed 's/.*\[//' \
            |sed 's/].*//' \
            |tr '\n' ',' \
            |sed 's/,$//'
    fi
}

function verify_roles() {
    [ $# -eq 0 ] && return 1
    local error

    for role in $*; do
        if ! knife role show $role &>/dev/null; then
            echo "ERROR: couldn't find role '$role'" >&2
            error=true
        fi
    done

    [ "$error" = "true" ] && return 1
    return 0
}

function get_default_env() {
    local name=$1

    if knife_node_exists $name; then
        # get environment 
        grep -w chef_environment $_PREV_NODE_DATA |cut -f4 -d'"'
    fi
}

function verify_env() {
    [ $# -eq 0 ] && return 1
    local name=$1

    if ! knife environment show $name &>/dev/null; then
        echo "ERROR: couldn't find environment '$name'" >&2
        return 1
    fi

    return 0
}

function knife_node_delete() {
    local name=$1

    if knife_node_exists $name; then
        echo
        echo "deleting existing node..."
        yes | knife node delete $name
    fi

    if knife client show $name &>/dev/null; then
        echo
        echo "deleting existing client..."
        yes | knife client delete $name
    fi
    echo
}

function create_json_file() {
    local name=$1
    local str_roles=$2
    local env=$3

    # explode roles string into array
    local ary_roles=($(explode $str_roles))

    local tmpfile=`mktemp`       # rename the temp file, otherwise:
    mv $tmpfile ${tmpfile}.json  # "FATAL: File must end in .js, .json, or .rb"

    cat > ${tmpfile}.json <<EOF
{
  "name": "$name",
  "chef_environment": "$env",
  "run_list": [
$(
    # unwind the roles
    local num_roles=${#ary_roles[@]}
    local i
    for ((i=0; i<$num_roles; i++)); do
        echo -n "   \"role[${ary_roles[$i]}]\""
        # add comma after every line except the last
        [ $i -lt $(($num_roles-1)) ] && echo -n ','
        echo
    done
)
  ]
}
EOF
    
    echo "${tmpfile}.json"
}

function knife_node_create() {
    local json_file=$1
    knife node from file ${json_file} #.json
    rm -f ${json_file} #.json   # not part of EXIT trap
}

function clean_known_hosts() {
    local name=$1
    local file=${2:-~/.ssh/known_hosts}

    perl -0pi.sav -e "s/^$name[, ].*$//ms; s/^.*,$name .*$//ms" $file
}

function get_user_input() {
    local prompt=$1
    local default=$2

    local response
    _INPUT=

    # if there's no default answer, then loop the question
    # until we get non-null data
    while [ -z "$_INPUT" ]; do
        read -p "$prompt [$default]: " response
        _INPUT=${response:-$default}
    done
}
function confirm_destroy() {
    local name=$1
    read -p "Really destroy $name? [y/N]: "
    if [ -z "$REPLY" ] || [[ ! "$REPLY" =~ ^[yY] ]]; then
        exit 2
    fi
}

function explode() {
    echo -n $1 |tr , ' '
}

function good_luck_half_configured() {
    local msg="$1"
    local file=$2

    cat >&2 <<EOF

==> ${msg}.

if you get it fixed, create the chef node with:
    knife node from file $file

EOF
    exit 1
}

function bail() {
    local msg="$1"

    echo "BUG!! $msg" >&2
    echo "exiting." >&2
    exit 3
}

function cleanup() {
    rm -f $_PREV_NODE_DATA

    _PREV_NODE_EXISTS=
    _PREV_NODE_DATA=
    _INPUT=
}

function set_traps() {
    trap cleanup EXIT
}

