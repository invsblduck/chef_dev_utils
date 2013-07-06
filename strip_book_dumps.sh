#!/bin/sh
#
# Removes the single debug line that is a dump of all the
# Chef::CookbookVersion objects (~1MB data in my runlist).
#
# reads stdin
cat | grep -v 'DEBUG: Cookbooks detail: '
