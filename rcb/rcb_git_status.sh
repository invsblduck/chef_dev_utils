#!/bin/sh -e

dirty=0

cd /git/rcbops/chef-cookbooks/cookbooks
echo "checking submodule status in `pwd` ..."

for submodule in *; do
    [ ! -d $submodule ] && continue
    cd $submodule
    if [ $(git status -s |wc -l) -gt 0 ]; then
        dirty=1
        echo; pwd
        git -c color.status=always status -s
    fi
    cd ..
done

exit $dirty
