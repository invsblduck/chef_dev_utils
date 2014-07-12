#!/bin/sh

trap "rm -f $tmp" EXIT
set -e

if ! pgrep monit >/dev/null; then
    echo "is monit running?"
    exit 1
fi

user=$(ps -C monit u |tail -1 |awk '{print $1}')
if [ -z "$user" -o "$user" = "USER" ]; then
    echo "couldn't determine which user monit is running as."
    exit 1
fi

if [ `whoami` != $user ]; then
    echo "please run script as user '$user'"
    exit 1
fi

tmp=`mktemp`
grep -w matching /etc/monit/conf.d/* |awk '{print $5 " " $6}' > $tmp
sed -i 's/"//g' $tmp

IFS=$'\n'   # why doesn't this work?
for regex in $(cat $tmp); do
    echo "|$regex|"
    #monit procmatch "$regex"
done
