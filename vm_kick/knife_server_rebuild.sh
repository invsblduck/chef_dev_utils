#!/bin/sh

# TODO get values from argv or env vars
#IMAGE=6a668bb8-fb5d-407a-9a89-6f957bced767     # ubuntu 12.04 (20130529)
#IMAGE=23b564c9-c3e6-49f9-bc68-86c7a9ab5018     # ubuntu 12.04 (20130713)
IMAGE=25a5f2e8-f522-4fe0-b0e0-dbaa62405c25      # centos 6.4 
#TEMPL=~/.chef/bootstrap/bc-ubuntu.erb
TEMPL=~/.chef/bootstrap/bc-centos.erb

if [ -z "$1" ]; then
    echo "usage: $0 <node>"
    exit 1
else
    node=$1
fi

# we don't need error handling around node name because
# the following command does the node logic for us.

knife rackspace server rebuild -S $node -I $IMAGE --template-file $TEMPL
exit $?
