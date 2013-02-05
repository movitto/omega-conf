#!/bin/sh

yum install git puppet
git clone http://github.com/movitto/omega-conf
cd omega-conf
# TODO where to get private data from
puppet apply ./recipes/omega/omega.pp --modulepath=./recipes
#puppet apply ./recipes/omega/mediawiki.pp --modulepath=./recipes
#puppet apply ./recipes/omega/verify.pp    --modulepath=./recipes
