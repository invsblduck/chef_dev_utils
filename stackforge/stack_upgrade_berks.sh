#!/bin/sh

set -e

# use locked version of berkshelf from github
sed -i "s/^gem .berkshelf.,.*/gem 'berkshelf', github: 'berkshelf\/berkshelf', ref: 'e30eb'/" Gemfile

# use hacked strainer gemspec that doesn't require old berkshelf
#   make sure you:
#     1. clone https://github.com/customink/strainer.git
#     2. checkout 'v3.3.0' tag
#     3. remove the berkshelf version constraint from strainer.gemspec
#     4. update Gemfile to use local :path => /blah
sed -i "s%^gem .strainer.\$%gem 'strainer', path: '~/code/strainer'%" Gemfile

# force chef 11.8.2 since 11.10.0 is broken as fuck
#sed -i "s/^gem .chef.,.*/gem 'chef', '11.8.2'/" Gemfile

#rm -f Gemfile.lock
bundle install

sed -i "s#^site :opscode#source 'http://api.berkshelf.com'#" Berksfile
rm -f Berksfile.lock
bundle exec berks install
