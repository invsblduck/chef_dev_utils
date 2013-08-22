#!/bin/sh -e

CONTAINER=bc-bitbucket
TARBALL=/tmp/bootstrap.tar.gz

script=$(whereis -b $0 |awk '{print $2}')
real_script=$(stat -c %N $script |sed 's/^.* -> //' |sed "s/'//g")

tar -C $(dirname $real_script) -cvzhf $TARBALL bootstrap
source ~/.swiftrc  # path required for non-interactive shell
echo uploading...
cd /tmp # swift will pick up the tmp/ subdir otherwise
swift upload $CONTAINER $TARBALL
