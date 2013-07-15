#!/bin/bash -e
echo "Fetching latest updates from GitHub..."
cd ~/git/rcbops/chef-cookbooks
git pull
git submodule update --init
