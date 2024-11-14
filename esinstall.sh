#!/bin/bash
# Script used to setup Elasticsearch. Can be run as a regular user (needs sudo)

ES_USER="elasticsearch"
ES_GROUP="$ES_USER"
ES_HOME="/usr/local/share/elasticsearch"
ES_CLUSTER="clustername"
ES_DATA_PATH="/var/data/elasticsearch"
ES_LOG_PATH="/var/log/elasticsearch"
ES_HEAP_SIZE="1g"
ES_MAX_OPEN_FILES=32000

# Path to main config
CONFIG="/etc/elasticsearch/elasticsearch.yml"

# Add group and user (without creating the homedir)
echo "Add user: $ES_USER"
sudo useradd -d $ES_HOME -M -s /bin/bash -U $ES_USER

# Bump max open files for the user
echo "$ES_USER soft nofile $ES_MAX_OPEN_FILES" | sudo tee -a /etc/security/limits.conf
echo "$ES_USER hard nofile $ES_MAX_OPEN_FILES" | sudo tee -a /etc/security/limits.conf

echo "Update system"
sudo yum update -y

sudo mkdir -p $ES_HOME

sudo chown -R $ES_USER:$ES_GROUP $ES_LOG_PATH $ES_HOME

echo "Install OpenJDK 11"
# Download and install Amazon Corretto 11 (OpenJDK)
cd /usr/local/share/elasticsearch
sudo wget https://corretto.aws/downloads/latest/amazon-corretto-11-x64-linux-jdk.tar.gz

# Extract the downloaded binary
sudo tar zxvf amazon-corretto-11-x64-linux-jdk.tar.gz

# Rename the extracted directory to 'java'
sudo mv amazon-corretto-11.* java

echo "Downloading Elasticsearch"
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.16.0-linux-x86_64.tar.gz -O elasticsearch.tar.gz

# Extract and move Elasticsearch
tar -xf elasticsearch.tar.gz
rm elasticsearch.tar.gz

sudo mv elasticsearch-*/* $ES_HOME
rm -rf elasticsearch-*

echo "Configuring Elasticsearch"
sudo mkdir -p $ES_LOG_PATH $ES_DATA_PATH
sudo chown -R $ES_USER:$ES_GROUP $ES_LOG_PATH $ES_DATA_PATH $ES_HOME

# Elasticsearch configuration
sudo tee $CONFIG <<EOF
cluster.name: $ES_CLUSTER
path.data: $ES_DATA_PATH
path.logs: $ES_LOG_PATH
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["127.0.0.1"]
bootstrap.memory_lock: true
EOF

echo "Setting JVM options"
# Set JVM heap size in jvm.options
echo "-Xms${ES_HEAP_SIZE}" | sudo tee /etc/elasticsearch/jvm.options.d/heap.options
echo "-Xmx${ES_HEAP_SIZE}" | sudo tee -a /etc/elasticsearch/jvm.options.d/heap.options

echo "Creating systemd service"
sudo tee /etc/systemd/system/elasticsearch.service <<EOF
[Unit]
Description=Elasticsearch
Documentation=https://www.elastic.co
Wants=network-online.target
After=network-online.target

[Service]
Environment=JAVA_HOME=/usr/local/share/elasticsearch/java
ExecStart=$ES_HOME/bin/elasticsearch
User=$ES_USER
LimitNOFILE=$ES_MAX_OPEN_FILES
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Elasticsearch
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service
echo "Elasticsearch setup completed. Use 'sudo systemctl status elasticsearch' to check status."
