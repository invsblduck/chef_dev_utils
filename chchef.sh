#!/bin/bash
 
_chchef() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=(
        $(compgen -W "$(pushd ${HOME}/.chef/servers.d &>/dev/null; \
            ls *; popd &>/dev/null)" -- $cur) \
    )
}
 
chchef() {
    local server=${1}

    if [ -z "${server}" ]; then
        basename $(readlink ~/.chef/chef_server_url)
        return 0
    fi
    
    if [ ! -e ${HOME}/.chef/servers.d/${server} ]; then
        return 1
    fi

    ln -sf ${HOME}/.chef/servers.d/${server} ${HOME}/.chef/chef_server_url
    cat ${HOME}/.chef/chef_server_url
}
 
complete -F _chchef chchef
