#!/bin/bash -e
cd /git/stackforge/openstack-chef-repo
knife role from file roles/*.rb
