
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
Copy the below contect.

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
   chmod +x configure_elasticsearch_network.sh
   ```
3. Run the script as `sudo`:
   ```bash
   sudo ./configure_elasticsearch_network.sh
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
   sudo systemctl enable elasticsearch
   ```

3. **Start Elasticsearch**:
   ```bash
   sudo systemctl start elasticsearch
   ```

4. **Check Elasticsearch Status**:
   ```bash
   sudo systemctl status elasticsearch
   ```

---

### **5. Verify Installation**

Test Elasticsearch by querying it:
```bash
curl -X GET "http://localhost:9200"
```

If Elasticsearch is running, you’ll see a JSON response with details about the version and cluster.

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

