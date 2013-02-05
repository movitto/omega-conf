#!/bin/sh

echo "Installing bootstrap dependencies and checking out components"
echo "This may take a few minutes to complete"

yum install git puppet
git clone http://github.com/movitto/omega-conf
cd omega-conf

echo "Copy private data into private/ directory and press any key to begin installation"
read

puppet apply ./recipes/omega/omega.pp     --modulepath=./recipes
puppet apply ./recipes/omega/mediawiki.pp --modulepath=./recipes
puppet apply ./recipes/omega/verify.pp    --modulepath=./recipes
