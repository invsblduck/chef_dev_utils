#!/bin/bash
 
_kick() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    [ ! -e ${HOME}/.fakecloudrc ] && return 1
    source ${HOME}/.fakecloudrc
    COMPREPLY=(
        $(compgen -W "$(pushd ${BASE_DIR}/instances &>/dev/null; \
            ls; popd &>/dev/null)" -- $cur) \
    )
}
 
kick() {
    local server=${1}

    if [ -z "${server}" ]; then
        sudo fakecloud list
        return 0
    fi
    rekick-fakecloud.sh $server
}
 
complete -F _kick kick
