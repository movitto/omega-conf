#!/bin/sh

yum install git puppet
git clone http://github.com/movitto/omega-conf
cd omega-conf
puppet ./recipes/omega/omega.pp --modulepath=./recipes
#puppet ./recipes/omega/mediawiki.pp --modulepath=./recipes
#puppet ./recipes/omega/verify.pp    --modulepath=./recipes
