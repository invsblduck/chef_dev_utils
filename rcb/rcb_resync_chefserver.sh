#!/bin/sh

set -e
rcb_switch_branch $1 -u
rcb_git_status.sh
yes | rcb_knife_bulkdelete.sh
rcb_knife_bulkupload.sh
rcb_knife_roles.sh

echo
read -n1 -p "overlay one of your branches? [y/N]: "
echo "not implemented"
