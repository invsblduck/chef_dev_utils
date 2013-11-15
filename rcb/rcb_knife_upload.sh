#!/bin/sh

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
    bookname=$(basename "$abspath")
    bookpath=$(dirname "$abspath")

    knife cookbook -V upload $bookname -o "$bookpath"
    cd -
done
