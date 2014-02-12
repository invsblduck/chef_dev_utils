#!/bin/sh

function usage() {
    cat <<EOF
usage: ${0##*/} [-n|--no-update] [<BRANCH>]

Fetch latest <BRANCH> from git remote and push it to chef server.

If <BRANCH> is omitted, default is 'master'.
--no-update means don't fetch latest changes from remote.

EOF
    exit 1
}

branch=
update="--update"

# 
# Parse options
#
TEMP=$(getopt -o hn --long help,no-update -n "${0##*/}" -- "$@")
if [ $? != 0 ]; then
    echo "getopt(1) failed! exiting." >&2
    exit 1
fi

# quotes required!
eval set -- "$TEMP"

while true; do
    case "$1" in
        -h|--help)
            usage
            exit 1
            ;;
        -n|--no-update)
            update=
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "getopt error! exiting." >&2
            exit 1
            ;;
    esac
done

# grab branch as non-option arg (convenience for user)
for arg do branch="$arg" ; done

set -e

# see if we can find 'chchef' function to get name of chef server
for dir in $HOME $HOME/.bash /etc/profile.d; do
    for file in chchef chchef.sh; do
        if [ -e $dir/$file ]; then
            . $dir/$file
            chef_server="$(chchef)"
            break 2
        fi
    done
done
chef_server=${chef_server:-'(unknown)'}

echo "syncing submodules ..."
rcb_switch_branch.sh "$update" "$branch"

echo
echo "checking submodule status in `pwd` ..."
rcb_git_status.sh

echo
echo "deleting cookbooks on server '$chef_server' ..."
yes | rcb_knife_bulkdelete.sh

echo
echo "uploading cookbooks to server '$chef_server' ..."
rcb_knife_bulkupload.sh

echo
echo "uploading roles to server '$chef_server' ..."
rcb_knife_roles.sh

#echo
#read -n1 -p "overlay one of your branches? [y/N]: "
#echo "not implemented"
