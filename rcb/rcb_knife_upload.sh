#!/bin/sh

repo=/git/rcbops/chef-cookbooks
cmd="knife cookbook -V upload -a -o $repo/cookbooks"

if ! $cmd; then
    # shit fails sometimes
    echo -e "\nTrying again...."
    $cmd
fi
