#!/bin/sh

yum install git puppet
git clone http://github.com/movitto/omega-conf
cd omega-conf
puppet apply ./recipes/omega/omega.pp --modulepath=./recipes

echo "Skipping over private data installation"
#puppet apply ./recipes/omega/mediawiki.pp --modulepath=./recipes
#puppet apply ./recipes/omega/verify.pp    --modulepath=./recipes
