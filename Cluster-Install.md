
### **1. Prerequisites**

- Ensure the operating system is supported (RHEL, CentOS, Fedora, Amazon Linux, Debian, or Ubuntu).
- You need `sudo` or root privileges.
- Ensure your system is up-to-date:
  ```bash
  sudo dnf update -y
  ```

---

Here's the updated script to include additional **network settings** for Elasticsearch in `/etc/sysctl.conf`. These settings optimize networking for Elasticsearch performance.
 ```bash
   sudo vi configure_elasticsearch_network.sh
   ```
Copy the below contect. edit hostname & ip address.

```bash
#!/bin/bash

# Ensure script is run as sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Set kernel parameters for Elasticsearch in /etc/sysctl.conf
echo "Updating /etc/sysctl.conf..."
cat <<EOL >> /etc/sysctl.conf
# Elasticsearch required parameters
vm.max_map_count=262144
fs.file-max=65536

# Network settings for Elasticsearch
net.core.somaxconn=65535
net.ipv4.tcp_retries2=5
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_tw_reuse=1
net.core.netdev_max_backlog=2000
net.core.rmem_max=16777216
net.core.wmem_max=16777216
EOL

# Apply the sysctl settings
sysctl -p

# Update /etc/security/limits.conf
echo "Updating /etc/security/limits.conf..."
cat <<EOL >> /etc/security/limits.conf
# Elasticsearch required limits
* soft nofile 65536
* hard nofile 65536
* soft nproc 2048
* hard nproc 4096
EOL

# Set the hostname
NEW_HOSTNAME="elasticsearch-node"
echo "Setting hostname to $NEW_HOSTNAME..."
hostnamectl set-hostname $NEW_HOSTNAME

# Update /etc/hosts
echo "Updating /etc/hosts..."
HOSTS_ENTRY="127.0.0.1 $NEW_HOSTNAME"
if ! grep -q "$NEW_HOSTNAME" /etc/hosts; then
    echo "$HOSTS_ENTRY" >> /etc/hosts
else
    echo "/etc/hosts already contains $NEW_HOSTNAME"
fi

echo "Configuration completed. Please verify the settings!"
```

### Explanation of Added Network Settings:
- **`net.core.somaxconn=65535`**: Increases the size of the queue of pending connections.
- **`net.ipv4.tcp_retries2=5`**: Reduces the number of retries for a TCP connection to close faster during timeouts.
- **`net.ipv4.ip_local_port_range=1024 65535`**: Expands the range of ports available for client connections.
- **`net.ipv4.tcp_tw_reuse=1`**: Enables reuse of sockets in the `TIME-WAIT` state, improving connection performance.
- **`net.core.netdev_max_backlog=2000`**: Increases the maximum number of packets allowed in the network device's queue.
- **`net.core.rmem_max` and `net.core.wmem_max`**: Adjust the maximum socket buffer sizes for send (`wmem`) and receive (`rmem`).

### Usage:
1. Save the updated script to a file, e.g., `configure_elasticsearch_network.sh`.
2. Make the script executable:
   ```bash
   sudo chmod +x configure_elasticsearch_network.sh
   ```
3. Run the script as `sudo`:
   ```bash
   sudo ./configure_elasticsearch_network.sh
   ```
3. Make usr /etc/hosts are updated by all cluster nodes and ping make sure all are can talk each other ( in aws set right security group All ICMP - IPv6 & All ICMP - IPv4 to be enabled)
   ```bash
   sudo vi /etc/hosts
   ```

### **2. Download and Install the Public Signing Key**

Import the GPG signing key for Elasticsearch:
```bash
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```

---

### **3. Create the Elasticsearch Repository**

#### For RHEL, CentOS, Fedora, or Amazon Linux

1. Create the repository file using the `cat <<EOF` format:
   ```bash
   sudo cat <<EOF > /etc/yum.repos.d/elasticsearch.repo
   [elasticsearch]
   name=Elasticsearch repository
   baseurl=https://artifacts.elastic.co/packages/8.x/yum
   gpgcheck=1
   gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
   enabled=1
   autorefresh=1
   type=rpm-md
   EOF
   ```

2. Verify the repository file:
   ```bash
   cat /etc/yum.repos.d/elasticsearch.repo
   ```

---

### **4. Install Elasticsearch**

1. **Install Elasticsearch Using Yum**:
   ```bash
   sudo dnf -y install elasticsearch
   ```

2. **Enable Elasticsearch to Start at Boot**:
   ```bash
   sudo cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.org
   sudo systemctl enable elasticsearch
   ```
---

In Elasticsearch, JVM parameters are typically updated in the **`jvm.options`** file. This file is used to configure Java Virtual Machine (JVM) settings, including heap size and garbage collection options.

### File Location:
The `jvm.options` file is located in the Elasticsearch configuration directory, typically:

- **Linux (package installations):** `/etc/elasticsearch/jvm.options`
- **Linux (tar.gz/zip installations):** `<elasticsearch-install-dir>/config/jvm.options`
- **Windows:** `<elasticsearch-install-dir>\config\jvm.options`

### Steps to Update JVM Parameters:

1. **Edit the `jvm.options` File:**
   Open the file in a text editor:
   ```bash
   sudo vi /etc/elasticsearch/jvm.options
   ```
   ```bash
   sudo sed -i 's/^-Xms[0-9]*[a-zA-Z]*$/-Xms2g/; s/^-Xmx[0-9]*[a-zA-Z]*$/-Xmx2g/' /etc/elasticsearch/jvm.options
   ```
2. **Set Heap Size:**
   Modify the following parameters to define the heap size for Elasticsearch:
   ```plaintext
   -Xms2g
   -Xmx2g
   ```
   - `-Xms`: Minimum heap size (e.g., `2g` for 2 GB).
   - `-Xmx`: Maximum heap size (e.g., `2g` for 2 GB).

   **Tip:** The values for `-Xms` and `-Xmx` should be the same to prevent heap resizing.

3. **Add/Modify Additional JVM Parameters:**
   Add or modify other JVM options as needed. For example:
   ```plaintext
   -XX:+UseG1GC
   -Djava.io.tmpdir=/tmp
   -XX:MaxDirectMemorySize=4g
   ```

### Important Notes:
- Ensure the heap size (`-Xms` and `-Xmx`) is no more than **50% of your total system memory**. Reserve the other 50% for the operating system and other processes.
- Monitor the Elasticsearch logs after updating the JVM parameters to confirm there are no errors:
   ```bash
   sudo journalctl -u elasticsearch -f
   ```
- Make sure the values align with your hardware resources and workload.

### Verify JVM Settings:
You can check the active JVM settings in the Elasticsearch logs or via the API:
```bash
curl -k -u elastic:esdemo https://$HOSTNAME:9200/_nodes/jvm?pretty
curl -k -u elastic:esdemo https://$HOSTNAME:9200/_nodes/jvm?pretty | jq '.nodes[] | {heap_max: .jvm.mem.heap_max_in_bytes, heap_used: .jvm.mem.heap_used_in_bytes}'

```


### Update /etc/elasticsearch/elasticsearch.yml file before start the Elasticsearch
```bash
sudo vi /etc/elasticsearch/elasticsearch.yml
```
---
```
cluster.name: es-demo
node.name: node1
network.host: es1
http.port: 9200
cluster.initial_master_nodes: ["node1"]
```
---

3. **Start Elasticsearch**:
   ```bash
   sudo systemctl start elasticsearch
   ```
---
4. **Check Elasticsearch Status**:
   ```bash
   sudo systemctl status elasticsearch
   ```
---
### ** Reset default password**
```bash
   sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -i -u elastic
   ```
### ** Verify Installation**

Test Elasticsearch by querying it:
```bash
curl -k -u elastic:esdemo https://es1:9200/_cluster/health?pretty
```
```bash
curl -k -u elastic:esdemo https://$HOSTNAME:9200/_cat/nodes?pretty
```
If Elasticsearch is running, you’ll see a JSON response with details about the version and cluster.

---
### ** Adding other node(s) in the cluster**
Run this command in node1 get the token
```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node
```
Run this command in node2 & node3
```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-reconfigure-node --enrollment-token <paste the token>
```
Update /etc/elasticsearch/elasticsearch.yml file before start the Elasticsearch
```bash
sudo vi /etc/elasticsearch/elasticsearch.yml
```
---
## Node2
```bash
sudo cat <<EOF > /etc/elasticsearch/elasticsearch.yml
cluster.name: es-demo
node.name: node2
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: es2
http.port: 9200
cluster.initial_master_nodes: ["node1", "node2", "node3"]
xpack.security.enabled: true
xpack.security.enrollment.enabled: true
xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12
discovery.seed_hosts: ["es1:9300","es2:9300","es3:9300"]
http.host: 0.0.0.0
transport.host: 0.0.0.0
EOF
```
---

## Node3 
```bash
sudo cat <<EOF > /etc/elasticsearch/elasticsearch.yml
cluster.name: es-demo
node.name: node3 
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: es3 
http.port: 9200
cluster.initial_master_nodes: ["node1", "node2", "node3"]
xpack.security.enabled: true
xpack.security.enrollment.enabled: true
xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12
discovery.seed_hosts: ["es1:9300","es2:9300","es3:9300"]
http.host: 0.0.0.0
transport.host: 0.0.0.0
EOF
```
---

``` bash
cluster.name: es-demo
node.name: node1
network.host: es1
http.port: 9200
cluster.initial_master_nodes: ["node1"]
```
---
Start Elasticsearch:
   ```bash
   sudo systemctl start elasticsearch
   ```
---

### **6. Final steps to update elasticsearch/elasticsearch.yml sync with all nodes**
Stop the nodes
 ```bash
 sudo systemctl stop elasticsearch
 ```
Edit the config file (discovery.seed_hosts: ["es1:9300","es2:9300","es3:9200"]
```bash
sudo vi /etc/elasticsearch/elasticsearch.yml
```
Start the node 
 ```bash
 sudo systemctl start elasticsearch
 ```
Verify
```bash
curl -k -u elastic:esdemo https://$HOSTNAME:9200/_cat/nodes?pretty
```

### ** Install Kibana
### ** Download and Install the Public Signing Key**

Import the GPG signing key for Elasticsearch:
```bash
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```

---

###  Create the Elasticsearch Repository**

#### For RHEL, CentOS, Fedora, or Amazon Linux

1. Create the repository file using the `cat <<EOF` format:
   ```bash
   sudo cat <<EOF > /etc/yum.repos.d/elasticsearch.repo
   [elasticsearch]
   name=Elasticsearch repository
   baseurl=https://artifacts.elastic.co/packages/8.x/yum
   gpgcheck=1
   gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
   enabled=1
   autorefresh=1
   type=rpm-md
   EOF
   ```

2. Verify the repository file:
   ```bash
   cat /etc/yum.repos.d/elasticsearch.repo
   ```

---

### **Install kibana**

1. **Install Elasticsearch Using Yum**:
   ```bash
   sudo dnf -y install kibana
   ```

2. **Enable Elasticsearch to Start at Boot**:
   ```bash
   sudo systemctl enable kibana
   ```
---
### Create Service Token
Run this command from any server server:
```bash
curl -X POST -u elastic:esdemo -k https://es1:9200/_security/service/elastic/kibana/credential/token/kibana_token
```
Run this command in kibana Server
```bash
sudo /usr/share/kibana/bin/kibana-keystore add elasticsearch.serviceAccountToken
```
Paste in the token after the prompt.

Change ownership of token files
```bash
sudo chown kibana:kibana /etc/kibana/*
```


---
To enable **default self-signed certificates** on Kibana for SSL, follow these steps:

---

### 1. **Default Self-Signed Certificates in Kibana**
Kibana includes default self-signed certificates located in:
- **Key**: `/usr/share/kibana/config/kibana.key`
- **Certificate**: `/usr/share/kibana/config/kibana.crt`

These certificates are pre-generated and suitable for testing or internal use. To enable them:

---

### 2. **Update `kibana.yml`**
Add the following settings to your `kibana.yml` file:

```yaml
server.ssl.enabled: true
server.ssl.key: /usr/share/kibana/config/kibana.key
server.ssl.certificate: /usr/share/kibana/config/kibana.crt
```

This enables SSL and configures Kibana to use the default certificates.

---

### 3. **Set the Public Base URL**
Ensure you configure the public base URL if accessing Kibana from outside the server:

```yaml
server.publicBaseUrl: "https://<public-ip-or-domain>:5601"
```

Replace `<public-ip-or-domain>` with your public IP or domain name.

---

### 4. **Restart Kibana**
Restart the Kibana service to apply the changes:

```bash
sudo systemctl restart kibana
```

---

### 5. **Verify SSL Configuration**
- Access Kibana in your browser using the `https` protocol:
  ```
  https://<your-kibana-server>:5601
  ```
  If you use the self-signed certificates, your browser may show a warning because the certificate is not from a trusted CA. You can bypass this warning for testing.

- Check Kibana logs for any issues:
  ```bash
  sudo journalctl -u kibana -f
  ```

---

### 6. **Optional: Use Custom Certificates**
If you want to replace the default certificates with your own, update the `server.ssl.key` and `server.ssl.certificate` paths in `kibana.yml` to point to your custom key and certificate files.

---

### 7. **Disable SSL Verification in Elasticsearch (Optional for Testing)**
If you encounter issues connecting Kibana to Elasticsearch over HTTPS with self-signed certificates, you can disable SSL verification in `kibana.yml` for testing:

```yaml
elasticsearch.ssl.verificationMode: none
```


---
### Update /etc/kibana/kibana.yml file before start the kibana
```bash
sudo vi /etc/kibana/kibana.yml
```
### backup orginal fole and Create a updated file
```bash
sudo mv /etc/kibana/kibana.yml /etc/kibana/kibana.yml.org
sudo cat <<EOF > /etc/kibana/kibana.yml
server.port: 5601
server.host: "0.0.0.0"
server.publicBaseUrl: "http://52.41.2.183:5601" # Public IP
server.ssl.enabled: false
elasticsearch.hosts: ["https://es1:9200","https://es2:9200","https://es3:9200"]
elasticsearch.ssl.verificationMode: none
logging:
  appenders:
    file:
      type: file
      fileName: /var/log/kibana/kibana.log
      layout:
        type: json
  root:
    appenders:
      - default
      - file
pid.file: /run/kibana/kibana.pid
EOF
```
---
```
server.port: 5601
server.host: 0.0.0.0
server.publicBaseUrl: "http://<PublicIp>:5601"
server.ssl.enabled: false
elasticsearch.hosts: ["https://es1:9200"]
elasticsearch.ssl.verificationMode: none
```
---
Start the kibana 
 ```bash
   sudo systemctl start kibana
   ```
Verify the kibana 
 ```bash
   sudo systemctl status kibana
   ```

To execute the same commands in **Kibana Dev Tools**, follow these steps:

---

### **1. Open Kibana Dev Tools**
1. Navigate to **Kibana** in your browser.
2. Go to **Management** > **Dev Tools** (or **Console**).

---

### **2. Create a Test Index**
Use the following query to create the `test_index`:

```json
PUT /test_index
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1
  },
  "mappings": {
    "properties": {
      "name": { "type": "text" },
      "age": { "type": "integer" },
      "city": { "type": "keyword" }
    }
  }
}
```

---

### **3. Add a Sample Document**
Add a document to the `test_index`:

```json
POST /test_index/_doc/1
{
  "name": "John Doe",
  "age": 30,
  "city": "New York"
}
```

Retrieve the document to verify it was added:

```json
GET /test_index/_doc/1
```

---

### **4. Test Shard Commands**

#### **Check Shard Allocation**
```json
GET /_cat/shards/test_index?v
```

#### **Shard Routing Information**
```json
GET /_cat/shards/test_index?h=index,shard,prirep,state,node,ip
```

#### **Shard Health**
```json
GET /_cluster/health/test_index
```

---

### **6. Configure Elasticsearch (Optional)**

If you need to make Elasticsearch accessible externally or customize its configuration:

1. Open the Elasticsearch configuration file:
   ```bash
   sudo vi /etc/elasticsearch/elasticsearch.yml
   ```

2. Set the required settings, such as:
   ```yaml
   network.host: 0.0.0.0
   cluster.name: my-cluster
   node.name: node-1
   discovery.seed_hosts: ["127.0.0.1"]
   ```

3. Restart Elasticsearch to apply the changes:
   ```bash
   sudo systemctl restart elasticsearch
   ```

---

### **7. Updating Elasticsearch**

With the repository configured, updating Elasticsearch is simple:
```bash
sudo yum -y update elasticsearch
```

---

