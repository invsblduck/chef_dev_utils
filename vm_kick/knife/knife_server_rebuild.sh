#!/bin/sh

if [ -z "$1" ]; then
    echo "usage: $0 <node> [centos|ubuntu]"
    exit 1
else
    node=$1
    distro=${2:-ubuntu}
fi

case $distro in
    ubuntu*)
        #IMAGE=6a668bb8-fb5d-407a-9a89-6f957bced767   # ubuntu 12.04 (20130529)
        #IMAGE=23b564c9-c3e6-49f9-bc68-86c7a9ab5018   # ubuntu 12.04 (20130713)
        IMAGE=25de7af5-1668-46fb-bd08-9974b63a4806    # ubuntu 12.04 (20131021)
        TEMPL=~/.chef/bootstrap/bc-ubuntu.erb
    ;;
    centos*)
        IMAGE=25a5f2e8-f522-4fe0-b0e0-dbaa62405c25    # centos 6.4
        TEMPL=~/.chef/bootstrap/bc-centos.erb
    ;;
    *)
        echo "${0##*/}: '$distro' not a supported distro!" >&2
        exit 1
    ;;
esac

# we don't need error handling around node name because
# the following command does the node logic for us.

knife rackspace server rebuild -S $node -I $IMAGE --template-file $TEMPL
exit $?
