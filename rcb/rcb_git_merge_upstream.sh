#!/bin/bash

valid_branches=(master grizzly havana icehouse)

b=`git symbolic-ref HEAD`
current_branch=${b##*/}

# 
# Check that current branch is what we want
#
if [ -z "$current_branch" ]; then
    echo "could not determine current git branch"
    exit 1
fi

valid=
for branch in "${valid_branches[@]}"; do
    [ $branch = $current_branch ] && valid=1 && break
done

if [ -z "$valid" ]; then
    echo "your current branch is not one of: ${valid_branches[*]}"
    echo "please stash your work and checkout one of those branches first."
    exit 1
fi

#
# Fetch the upstream commits and merge them
#
# TODO verify remote 'upstream' exists
set -e
git fetch -v upstream

if [ $(git rev-list --left-right upstream/${current_branch}...HEAD |wc -l) != 0 ]
then
    read -n1 -p "view the diffs? [Y/n]: "
    if [[ "${REPLY:-y}" =~ [yY] ]]; then
        git -p diff $current_branch upstream/$current_branch
    fi

    read -n1 -p "merge commits? [Y/n]: "
    if [[ "${REPLY:-y}" =~ [yY] ]]; then
        git merge upstream/$current_branch
    fi
fi
