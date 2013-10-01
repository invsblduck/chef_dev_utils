#!/bin/sh

set -e
rcb_git_pull.sh $1
rcb_git_status.sh
rcb_knife_upload.sh

echo
read -n1 -p "overlay one of your branches? [y/N]: "
echo "not implemented"
