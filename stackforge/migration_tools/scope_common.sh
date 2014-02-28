#!/bin/sh

if [ -z "$1" ]; then
    cat <<EOF
usage: ${0##*/} <sf_common_attrs_file>

example:
    \$ ${0##*/} ./stackforge/cookbook-openstack-common/attributes/default.rb

EOF
    exit 1
fi

if [ ! -f $1 ]; then
    echo "'$1' is not a regular file." >&2
    exit 1
fi

out=stack_common_scoped.rb
cp -v $1 $out

sed -ri 's/(override|default|default_unless)\[/@common[/g' $out
sed -ri 's/kernel\[/@kernel[/g' $out
sed -ri 's/lsb\[/@lsb[/g' $out
sed -ri 's/(case|if|unless) platform/\1 @platform/g' $out
sed -ri 's/(case|if|unless) platform_family/\1 @platform_family/g' $out

cat <<EOF
edit the output file and replace/defang all occurances of:
    node[
    platform
    platform_family

for swift remove the 'info' variable
EOF
