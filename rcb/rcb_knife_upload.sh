#!/bin/sh

set -e 

function usage() {
    #echo "usage: ${0##*/} <cookbook> [<branch>]"
    echo "usage: ${0##*/} <directory>"
    exit 1
}

[ -z "$1" ] && usage
[[ "$1" =~ ^--?h(elp)? ]] && usage

if [ ! -d "$1" ]; then
    echo "'$1' is not a directory..."
    echo "should be a cookbook (see --help)."
    exit 1
fi

cd "$1"
abspath="$(pwd)"
bookname=$(basename "$abspath")
bookpath=$(dirname "$abspath")

knife cookbook -V upload $bookname -o "$bookpath"
