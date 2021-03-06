#!/bin/sh

sandboxvm=dev
book_path=

function usage() {
    cat <<EOF
usage: ${0##*/} [<DIR>]

rsyncs <DIR> to sandbox VM '$sandboxvm' and runs rspec.
<DIR> defaults to cookbook containing current CWD.

EOF
    exit 0
}

if [ -n "$1" ]; then
    if [[ "$1" =~ ^--?h(elp)? ]]; then
        usage
    else
        if [ ! -d "$1" ]; then
            echo "ERROR: '$1' is not a directory" >&2
            exit 1
        fi
        book_path="$1"
    fi
fi

cd ${book_path:-.}
path=$(pwd)

while [ -n "$path" ]; do
    cd $path
    if [ -d spec ] || [[ $path/ =~ /spec/ ]]; then
        book_path=${path%%/spec*}
        break
    fi
    path=${path%/*}
done

if [ -z "$book_path" -o ! -e "$book_path"/metadata.rb ]; then
    echo "ERROR: couldn't determine current cookbook from PWD! (where are you?)"
    exit 1
fi

# dereference symlink
if [ -L "$book_path" ]; then
    book_path="$(dirname $book_path)/$(readlink $book_path |sed 's#/$##')"
fi

set -e
rsync -av --delete --exclude .git $book_path $sandboxvm:code/

cookbook=$(basename $book_path)
echo -e "\n\e[1;30mRunning tests for\e[0m \e[1;32m$cookbook\e[0m"

ssh $sandboxvm "source .bash_profile && \
                cd code/$cookbook && \
                rm -rf .bundle && \
                bundle install && \
                bundle exec rspec spec/ --color"

