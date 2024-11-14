#!/bin/bash
# Script used to setup elasticsearch. Can be run as a regular user (needs sudo)

ES_USER="elasticsearch"
ES_GROUP="$ES_USER"
ES_HOME="/usr/local/share/elasticsearch"
ES_CLUSTER="clustername"
ES_DATA_PATH="/var/data/elasticsearch"
ES_LOG_PATH="/var/log/elasticsearch"
ES_HEAP_SIZE=1024
ES_MAX_OPEN_FILES=32000

# Path to main config
CONFIG="$ES_HOME/config/elasticsearch.yml"

# Path to service wrapper config
SERVICE_CONFIG="$ES_HOME/bin/service/elasticsearch.conf"

# Add group and user (without creating the homedir)
echo "Add user: $ES_USER"
sudo useradd -d $ES_HOME -M -s /bin/bash -U $ES_USER

# Bump max open files for the user
sudo sh -c "echo '$ES_USER soft nofile $ES_MAX_OPEN_FILES' >> /etc/security/limits.conf"
sudo sh -c "echo '$ES_USER hard nofile $ES_MAX_OPEN_FILES' >> /etc/security/limits.conf"

cd ~

echo "Update system"
sudo yum update -y

echo "Install JRE"
sudo yum install jre -y

echo "Downloading elasticsearch"
wget https://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-0.19.7.tar.gz -O elasticsearch.tar.gz

tar -xf elasticsearch.tar.gz
rm elasticsearch.tar.gz
mv elasticsearch-* elasticsearch
sudo mkdir -p $ES_HOME
sudo mv elasticsearch/* $ES_HOME
rm -rf elasticsearch

echo "Install service wrapper"
curl -L http://github.com/elasticsearch/elasticsearch-servicewrapper/tarball/master | tar -xz
sudo mv *servicewrapper*/service $ES_HOME/bin/
rm -rf *servicewrapper*
sudo $ES_HOME/bin/service/elasticsearch install

echo "Fix configuration files"
sudo sed -i "s|^# bootstrap.mlockall:.*$|bootstrap.mlockall: true|" $CONFIG
sudo sh -c "echo 'path.logs: $ES_LOG_PATH' >> $CONFIG"
sudo sh -c "echo 'path.data: $ES_DATA_PATH' >> $CONFIG"
sudo sh -c "echo 'cluster.name: $ES_CLUSTER' >> $CONFIG"

# Fix these two in $CONFIG if your network does not do multicast
# network.host: <ip of current node>
# discovery.zen.ping.unicast.hosts: ["<ip of other node in the cluster>"]

sudo sed -i "s|set\.default\.ES_HOME=.*$|set.default.ES_HOME=$ES_HOME|" $SERVICE_CONFIG
sudo sed -i "s|set\.default\.ES_HEAP_SIZE=[0-9]\+|set.default.ES_HEAP_SIZE=$ES_HEAP_SIZE|" $SERVICE_CONFIG

sudo sed -i "s|^#RUN_AS_USER=.*$|RUN_AS_USER=$ES_USER|" $ES_HOME/bin/service/elasticsearch
sudo sed -i "s|^#ULIMIT_N=.*$|ULIMIT_N=$ES_MAX_OPEN_FILES|" $ES_HOME/bin/service/elasticsearch

echo "Create data and log directories and fix permissions"
sudo mkdir -p $ES_LOG_PATH $ES_DATA_PATH
sudo chown -R $ES_USER:$ES_GROUP $ES_LOG_PATH $ES_DATA_PATH $ES_HOME

echo "Install plugins"
sudo $ES_HOME/bin/plugin -install karmi/elasticsearch-paramedic

# Start the daemon
sudo /etc/init.d/elasticsearch start
