#!/bin/bash -e
cd ~/git/rcbops/chef-cookbooks
knife role from file roles/*.rb
