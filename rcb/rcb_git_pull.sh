#!/bin/bash -e
echo "Fetching latest updates from GitHub..."
cd ~/git/rcbops/chef-cookbooks
git checkout ${1:-master}
git pull
git submodule update --init
