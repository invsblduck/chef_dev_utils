#!/bin/bash
read -p "Really bulk delete all cookbooks on your chef server? [y/N]: "
[[ ! ${REPLY:-n} =~ ^[yY] ]] && echo "Aborting" && exit 1

yes | knife cookbook bulk delete '.*' --purge
