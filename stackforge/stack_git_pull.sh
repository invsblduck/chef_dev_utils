#!/bin/sh

set -e
cd /git/stackforge
for d in *; do
    echo -e "\e[1;30m$d\e[0m"
    if pushd $d >/dev/null; then
        b=`git symbolic-ref HEAD`
        current_branch=${b##*/}
        if [ "$current_branch" != master ]; then
            # TODO determine if workspace dirty
            git checkout master
        fi
        git pull
        popd >/dev/null
    fi
    echo
done
