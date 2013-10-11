#!/bin/bash -e
echo "Updating roles..."
cd ~/git/rcbops/chef-cookbooks
knife role from file roles/*.rb
