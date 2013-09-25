#!/bin/sh -e

CONTAINER=bc-bitbucket
TARBALL=bootstrap.tar.gz
OUTDIR=/tmp

script=$(whereis -b $0 |awk '{print $2}')
real_script=$(stat -c %N $script |sed 's/^.* -> //' |sed "s/'//g")

tar -C $(dirname $real_script) -cvzhf $OUTDIR/$TARBALL bootstrap
source ~/.swiftrc  # path required for non-interactive shell
echo uploading...
cd $OUTDIR # swift will pick up the tmp/ subdir otherwise
swift upload $CONTAINER $TARBALL
