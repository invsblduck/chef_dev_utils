#!/bin/sh

if [ $# -ne 2 ]; then
    cat <<EOF
usage: ${0##*/} <file1> <file2>

where <file1> contains RPC attrs and <file2> contains coresponding SF attrs.

example:
    \$ ${0##*/} ./rpc/glance/attributes/default.rb \\
        ./stackforge/cookbook-openstack-image/attributes/default.rb

EOF
    exit 1
fi

for f in $*; do
    if [ ! -f $f ]; then
        echo "'$f' is not a regular file." >&2
        exit 1
    fi
done

out1="rpc_$(basename $1 .rb)_scoped.rb"
out2="stack_$(basename $2 .rb)_scoped.rb"

cp -v $1 $out1
cp -v $2 $out2

sed -ri 's/(override|default|default_unless)\[/@hash1[/g' $out1
sed -ri 's/(override|default|default_unless)\[/@hash2[/g' $out2
################################################### ^

for f in $out1 $out2; do
    sed -ri 's/kernel\[/@kernel[/g' $f
    sed -ri 's/lsb\[/@lsb[/g' $f
    sed -ri 's/(case|if|unless) platform/\1 @platform/g' $f
    sed -ri 's/(case|if|unless) platform_family/\1 @platform_family/g' $f
done

cat <<EOF
edit the files and replace/defang all occurances of:
    node[
    platform
    platform_family

for swift remove the 'info' variable
EOF
