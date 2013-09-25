#!/bin/bash -e
echo "Fetching latest updates from GitHub..."
cd ~/git/rcbops/chef-cookbooks
git checkout master
git pull
git submodule update --init
