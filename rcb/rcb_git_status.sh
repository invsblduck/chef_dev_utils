#!/bin/sh -e

# Could probably do something with `git submodule status', but this
# feels a bit more direct and in-depth, and I'm learning Git ;-)

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
