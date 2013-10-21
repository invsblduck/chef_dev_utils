#!/bin/bash -e

REPO_DIR=/git/rcbops/chef-cookbooks

branch=master
update=

function usage() {
    cat <<EOF
usage: ${0##*/} [-u|--update] {-b|--branch <BRANCH>}

Change cookbook directory ($REPO_DIR) to branch <BRANCH>.
Defaults to 'master' if none supplied.

--update performs \`git pull' after changing branches.

--branch literal can be omitted for ease of use
(ie., pass <BRANCH> as non-option argument).

EOF
}

# 
# Parse options
#
TEMP=$(getopt -o hb:u --long help,branch:,update -n "${0##*/}" -- "$@")
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
        -u|--update)
            update=true
            shift
            ;;
        -b|--branch)
            branch=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Internal error!" >&2
            exit 1
            ;;
    esac
done

# grab branch as non-option arg if -b wasn't used
# (convenience for user)
for arg do branch="$arg" ; done       

# 
# Do the needful
#
cd $REPO_DIR
git checkout $branch

if [ -n "$update" ]; then
    echo "Merging latest updates from GitHub..."
    git pull
fi

git submodule sync
git submodule update --init
