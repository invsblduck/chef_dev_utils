#!/bin/bash

# Script to run chef-client with debug logging and save logs to /tmp as
# chef.log.1, chef.log.2, chef.log.3, etc. (with each successive run of script)

LOGBASE=/tmp/chef.log
logfile=${LOGBASE}.1

if [ -e $logfile ]
then
    # find the next number to use
    prev=$(
        ls ${LOGBASE}.* \
            |grep -E 'log.[0-9]+$' \
            |sort -Vr \
            |head -1 \
            |cut -f3 -d.
    )
    logfile=${LOGBASE}.$(($prev+1))
fi

sudo chef-client -l debug -L $logfile
rc=$?

cat <<EOF

RETURNED: $rc

debug output written to $logfile

EOF

exit $rc
