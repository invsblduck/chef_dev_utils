#!/bin/bash

set -e 

# help
function usage() {
    echo "usage: ${0##*/} <dir> [<dir> ...]"
    exit 1
}
[ -z "$1" ] && usage
[[ "$1" =~ ^--?h(elp)? ]] && usage

# Basic sanity checking
for dir in $*; do
    if [ ! -d "$dir" ]; then
        echo "'$dir' is not a directory..."
        dirty=1
    fi
done
if [ -n "$dirty" ]; then
    echo
    echo "argument should be path to a cookbook (see --help)."
    exit 1
fi

# iterate and upload
for cookbook in $*; do
    cd "$cookbook"
    abspath="$(pwd)"

    # deref symlink
    if [ -L "$abspath" ]; then
        abspath="$(dirname $abspath)/$(readlink $abspath)"
    fi

    # NOTE: Decided instead to clone StackForge cookbooks into directories
    # named by the cookbooks' metadata instead of GitHub repos. No need to
    # munge copies into temp dir then.

        # XXX Chef is fuct and knows not whether to honor metadata name,
        # directory name, or both; in the case of 11.6.2 and 11.8.2, metadata
        # name cannot be used to upload cookbooks (despite what bug reports and
        # arguing may claim), thus we have to change the directory name.

        # get metadata name
        #metaname=$(
        #    grep -w '^name' metadata.rb \
        #    |awk '{print $2}' \
        #    |sed 's/"//g' \
        #    |sed "s/'//g"
        #)

        # copy cookbook to temp dir (named by metadata name) and upload
        #tmpdir=$(mktemp -d)
        #cp -a "$abspath" $tmpdir/$metaname
        #knife cookbook -V upload $metaname -o $tmpdir --force

    parent_dir=$(dirname  "$abspath")
    cookbook_dir=$(basename "$abspath")

    knife cookbook -V upload "$cookbook_dir" -o "$parent_dir" --force
    cd - >/dev/null
done
