#!/bin/bash

## Wrapper script to run tests under Travis CI
## We need to:
## - install solr
## - install Ckan in a virtualenv

set -e  # Fail soon!

## We assume this script will be launched inside the repository
REPO_ROOT="$PWD"

# cd "$( dirname "$0" )"

if [ -z "$VIRTUAL_ENV" ]; then
    echo "Virtual env not set"
    exit 1
fi

if [ -z "$REPO_URL" ]; then
    REPO_URL=https://github.com/ckan/ckan
fi
if [ -z "$REPO_BRANCH" ]; then
    REPO_BRANCH=master
fi


## Set password for postgres user
##------------------------------------------------------------
sudo -u postgres -H psql -c "ALTER USER postgres PASSWORD 'pass'"


## Install Solr
##------------------------------------------------------------
sudo apt-get update -q
sudo apt-get install -q -y solr-jetty
sudo service jetty stop

sudo tee /etc/default/jetty <<EOF
NO_START=0
JETTY_HOST=127.0.0.1
JETTY_PORT=8983
JAVA_HOME=$JAVA_HOME
EOF


## Download Ckan
##------------------------------------------------------------
echo "Downloading and installing Ckan (in ${VIRTUAL_ENV})"
mkdir -p ${VIRTUAL_ENV}/src
mkdir -p ${VIRTUAL_ENV}/etc/ckan
git clone "$REPO_URL" -b "$REPO_BRANCH" --depth=1 "$VIRTUAL_ENV"/src/ckan

sudo cp "$VIRTUAL_ENV"/src/ckan/ckan/config/solr/schema-2.0.xml /etc/solr/conf/schema.xml
sudo service jetty start

cp "$VIRTUAL_ENV"/src/ckan/ckan/config/who.ini "${VIRTUAL_ENV}/etc/ckan/"

## Make sure we are in the correct path
cd "${REPO_ROOT}"
pip install --allow-all-external -r ./requirements.txt
pip install --allow-all-external -r ./requirements-test.txt
pip install --allow-all-external -r "$VIRTUAL_ENV"/src/ckan/requirements.txt

cd "$VIRTUAL_ENV"/src/ckan/ && python setup.py install
