#!/bin/sh

# TODO get values from argv or env vars
IMAGE=6a668bb8-fb5d-407a-9a89-6f957bced767
TEMPL=~/.chef/bootstrap/bc-ubuntu.erb

if [ -z "$1" ]; then
    echo "usage: $0 <node>"
    exit 1
else
    node=$1
fi

# we don't need error handling around node name because
# the following command does the node logic for us.

knife rackspace server rebuild -S $node -I $IMAGE --template-file $TEMPL
