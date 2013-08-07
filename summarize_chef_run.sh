#!/bin/bash
#
#   usage: ./summarize_chef_run.sh <CHEF_LOG_FILE>
#
# This script summarizes changes made by chef-client.  It might be useful if
# your chef-client output is several thousands lines long.
#
# I usually run chef with `sudo chef-client -l debug -L chef.log',
# and then run: summarize_chef_run.sh chef.log
#
#   written by invsblduck <invsblduck \u0040 gmail \u002e com>


# keywords to grab from log
ACTION_WORDS=(
    'backed up to'
    'ran successfully'
    'created directory'
    'created file'
    'updated file contents'
    'owner changed'
    'group changed'
    started
)

function usage 
{
    echo "usage: ${0##*/} <CHEF_LOG_FILE>"
    exit 1
}

# usage
[ -z "$1" ] && usage
[[ $1 =~ ^--?h(elp)? ]] && usage

log=$1

# sanity
if [ ! -r $log ]
then
    echo >&2 "${0##*/}: '$log': file not readable"
    exit 1
fi

# output files
for dir in $(dirname $log) . /tmp; do
    [ -w $dir ] && outdir=$dir && break
done

outfile_actions="$outdir/$(basename $log)_actions"
outfile_patches="$outdir/$(basename $log)_patches"

# confirm overwrite
if [ -e $outfile_actions -o -e $outfile_patches ]
then
    echo "==> $outfile_actions and/or $outfile_patches already exists;"
    read -n1 -p "overwrite files? [Y/n]: "
    [ -n "$REPLY" ] && [[ ! $REPLY =~ ^[yY] ]] && echo && exit 1
    rm -f $outfile_actions $outfile_patches
fi

# grab keyword actions
echo "==> writing $outfile_actions"
for pattern in "${ACTION_WORDS[@]}"; do
    grep -E "$pattern" $log >> $outfile_actions
done

tmp1=`mktemp`   # temporarily store some file names
tmp2=`mktemp`   #
tmp3=`mktemp`   #

# grab names of backup files
grep 'backed up to' $outfile_actions \
    |cut -f3 -d'[' \
    |awk '{ print $5 }' \
    > $tmp1

# grab names of current/target files
grep 'backed up to' $outfile_actions \
    |cut -f3 -d'[' \
    |cut -f1 -d']' \
    |sed 's#^apache2\.conf$#/etc/apache2/apache2.conf#' \
    > $tmp2

# grab names of newly-created files (no backups)
grep 'created file' $outfile_actions \
    |cut -f3 -d'[' \
    |awk '{ print $4 }' \
    > $tmp3

# diff each of the files against their backup counterparts
echo "==> writing $outfile_patches"
paste $tmp1 $tmp2 |while read names
do
    sudo diff -r -U3 $names
    echo
done > $outfile_patches

# diff each new file against /dev/null to make a patch
for file in $(cat $tmp3); do
    sudo diff -U3 /dev/null $file
    echo
done >> $outfile_patches

# remove temp files
rm -f $tmp1 $tmp2 $tmp3

# show actions in pager
less $outfile_actions
