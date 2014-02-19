#!/bin/sh

sandboxvm=dev
book_path=

# FIXME?
berks_script_name=stack_upgrade_berks.sh
berks_script_path=$(which --skip-alias --skip-functions $berks_script_name)

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
else
    export path=$(pwd)
    while [ -n "$path" ]; do
        cd $path
        if [ -d spec ] || [[ $path/ =~ /spec/ ]]; then
            book_path=${path%%/spec*}
            break
        fi
        path=${path%/*}
    done
fi

if [ -z "$book_path" -o ! -e "$book_path"/metadata.rb ]; then
    echo "ERROR: couldn't determine current cookbook from PWD! (where are you?)"
    exit 1
fi

if [ -z "$berks_script_path" ]; then
    echo "ERROR: is \`$berks_script_name' in your \$PATH?  can't find it."
    exit 1
fi

set -e
rsync -av $berks_script_path $sandboxvm:
rsync -av --delete --exclude .git $book_path $sandboxvm:code/

cookbook=$(basename $book_path)

echo -e "\n\e[1;30mUpgrading Berkshelf in bundle...\e[0m"
ssh $sandboxvm "source .bash_profile && \
                cd code/$cookbook && \
                rm -rf .bundle && \
                ~/$berks_script_name"

#echo -e "\n\e[1;30mChecking bundle..."
#if ! ssh $sandboxvm "cd code/$cookbook && bundle check"; then
#fi

echo -e "\n\e[1;30mRunning tests for\e[0m \e[1;32m$cookbook\e[0m"
ssh $sandboxvm "source .bash_profile && \
                cd code/$cookbook && \
                bundle exec strainer test"
