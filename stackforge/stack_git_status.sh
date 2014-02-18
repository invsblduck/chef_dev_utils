#!/bin/sh

STACKFORGE_DIR=/git/stackforge

function usage() {
    cat <<EOF
usage: ${0##*/} [-v|--verbose]

iterate through repos in $STACKFORGE_DIR and show whether
current branch is not 'master' and/or if workspace is dirty.

verbose flag causes more output from git-status(1), including patches.

EOF
}

TEMP=$(getopt -o hv --long help,verbose -n "${0##*/}" -- "$@")
if [ $? != 0 ]; then
    echo "getopt(1) failed! exiting." >&2
    exit 1
fi

# quotes required!
eval set -- "$TEMP"

while true; do
    case "$1" in
        -h|--help)
            usage
            exit 1
            ;;
        -v|--verbose)
            verbose=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Internal error!" >&2
            exit 1
            ;;
    esac
done

set -e

cd $STACKFORGE_DIR
for d in *; do
    b=
    current_branch=
    dirty=

    echo -e "\e[1;30m$d\e[0m"

    if pushd $d >/dev/null; then
        b=`git symbolic-ref HEAD`
        current_branch=${b##*/}
        [ $(git status --porcelain |wc -l) != 0 ] && dirty=true

        if [ "$current_branch" != master ]; then
            echo -e "\e[0;31;40mOn branch \e[0m\e[1;31;40m${current_branch}\e[0m"
        fi

        if [ -n "$verbose" ]; then
            git status
            git --no-pager diff
            echo
        else
            if [ -n "$dirty" ]; then
                git status --porcelain
                echo
            fi
        fi
        popd >/dev/null
    fi
done
