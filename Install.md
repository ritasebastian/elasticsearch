Here’s a breakdown of how to configure Elasticsearch kernel parameters by updating:

1. **`sudo vi /etc/sysctl.conf`** for kernel parameters that require `sysctl`.
2. **`sudo vi /etc/security/limits.conf`** for file descriptor and process limits specific to the Elasticsearch user.

### 1. **Configure Kernel Parameters in `/etc/sysctl.conf`**
Add these lines to `/etc/sysctl.conf` to set the required kernel parameters for Elasticsearch:

```bash
# Maximum number of memory map areas a process may have
vm.max_map_count=262144

# Maximum file handles for the entire system
fs.file-max=65535

# Network settings
net.ipv4.tcp_retries2=5          # Reduces TCP retries
net.ipv4.tcp_fin_timeout=30      # Reduces the TCP FIN timeout
net.ipv4.tcp_keepalive_time=300  # Enables TCP keepalive

# Swappiness setting to reduce swapping
vm.swappiness=1

# Disk I/O performance settings
vm.dirty_ratio=40
vm.dirty_background_ratio=10
```

After making changes to `/etc/sysctl.conf`, apply them with:

```bash
sudo sysctl -p
```

### 2. **Configure User Limits in `/etc/security/limits.conf`**
Edit the `/etc/security/limits.conf` file to set file descriptor and process limits specifically for the `elasticsearch` user. Add the following lines:

```bash
# Increase the maximum number of open files for Elasticsearch
elasticsearch soft nofile 65536
elasticsearch hard nofile 65536

# Increase the maximum number of processes for Elasticsearch
elasticsearch soft nproc 4096
elasticsearch hard nproc 4096
```

### 3. **Disable Transparent Huge Pages (THP) with `rc.local` or Systemd Service**

Since Transparent Huge Pages (THP) can impact Elasticsearch performance, you can disable it using either `/etc/rc.local` or by creating a custom systemd service.

**Option A: Using `/etc/rc.local` (if available)**

Add these lines to `/etc/rc.local`:

```bash
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
```

Then, make sure `rc.local` has execution permission:

```bash
sudo chmod +x /etc/rc.local
```

cluster.name: my-cluster  # Name of the cluster (must be the same for all nodes)
network.host: 0.0.0.0     # Bind to all available interfaces
http.port: 9200           # HTTP port for REST API

# Discovery settings to locate other nodes
discovery.seed_hosts: ["es1", "es2", "es3"]
cluster.initial_master_nodes: ["es1", "es2", "es3"]

# Security settings (if needed)
# xpack.security.enabled: true
# xpack.security.transport.ssl.enabled: true

# Path to store data
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch

######
node.name: es1            # Unique name for the node
node.roles: ["master", "data"]  # Master-eligible and data node
network.host: es1         # Hostname or IP address of this node

node.name: es2            # Unique name for the node
node.roles: ["master", "data"]  # Master-eligible and data node
network.host: es2         # Hostname or IP address of this node

node.name: es3            # Unique name for the node
node.roles: ["master", "data"]  # Master-eligible and data node
network.host: es3         # Hostname or IP address of this node


**Option B: Create a Systemd Service**

If `/etc/rc.local` is not available, create a custom systemd service to disable THP:

1. Create a new service file:

   ```bash
   sudo nano /etc/systemd/system/disable-thp.service
   ```

2. Add the following content to the file:

   ```ini
   [Unit]
   Description=Disable Transparent Huge Pages (THP)
   After=sysinit.target

   [Service]
   Type=oneshot
   ExecStart=/bin/bash -c "echo never > /sys/kernel/mm/transparent_hugepage/enabled"
   ExecStart=/bin/bash -c "echo never > /sys/kernel/mm/transparent_hugepage/defrag"

   [Install]
   WantedBy=multi-user.target
   ```

3. Enable and start the service:

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable disable-thp.service
   sudo systemctl start disable-thp.service
   ```

This configuration should optimize your Elasticsearch environment by setting appropriate kernel parameters and user limits.

To install Elasticsearch 8.16 on an Amazon Linux 2023 (Amazon Linux 3) EC2 instance, follow these steps:

1. **Update the System Packages**:
   ```bash
   sudo yum update -y
   ```

2. **Install Java**:
   Elasticsearch requires Java. Amazon Linux 2023 comes with Amazon Corretto, a production-ready distribution of OpenJDK. Install it as follows:
   ```bash
   sudo yum install -y java-17-amazon-corretto
   ```

3. **Download and Install Elasticsearch**:
   Download the RPM for Elasticsearch 8.16 from Elastic's official site and install it.

   ```bash
   wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.16.0-x86_64.rpm
   sudo rpm --install elasticsearch-8.16.0-x86_64.rpm
   ```

4. **Configure Elasticsearch** (Optional):
   Modify the configuration file if needed:
   ```bash
   sudo vi /etc/elasticsearch/elasticsearch.yml
   ```
   Set values like `network.host` and `http.port` as per your requirements. For example:
   ```yaml
   network.host: 0.0.0.0
   http.port: 9200
   ```

5. **Set Up System Limits**:
   Elasticsearch recommends increasing the number of open files. Modify system limits:
   ```bash
   sudo bash -c "echo 'elasticsearch soft nofile 65535' >> /etc/security/limits.conf"
   sudo bash -c "echo 'elasticsearch hard nofile 65535' >> /etc/security/limits.conf"
   ```

6. **Enable and Start Elasticsearch**:
   Set up Elasticsearch to start on boot and start the service.
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable elasticsearch
   sudo systemctl start elasticsearch
   ```

7. **Verify Elasticsearch Status**:
   Check if Elasticsearch is running properly:
   ```bash
   sudo systemctl status elasticsearch
   ```

8. **Access Elasticsearch**:
   Test the Elasticsearch installation by running:
   ```bash
   curl -X GET "localhost:9200/"
   ```
   If Elasticsearch is configured to accept remote connections, replace `localhost` with your instance's IP.

This should complete the installation of Elasticsearch 8.16 on Amazon Linux 2023 EC2. 

To reset the password for the default `elastic` user in Elasticsearch and to check the cluster status, follow these steps:

### 1. Resetting the Password for the `elastic` User
To reset the password, use the `elasticsearch-reset-password` command provided by Elasticsearch:

```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
```

This command will prompt you to either automatically generate a new password or set a custom password for the `elastic` user.

### 2. Checking the Cluster Status
To check the status of your Elasticsearch cluster, use the following command:

```bash
curl -u elastic:<password> -X GET "https://localhost:9200" --insecure
```

Replace `<password>` with the current password for the `elastic` user.

The output will include details such as:
- `cluster_name`: The name of your cluster.
- `status`: Indicates the health of the cluster (e.g., `green`, `yellow`, or `red`).
- `number_of_nodes`: The number of nodes in the cluster.
- `active_shards`, `relocating_shards`, `initializing_shards`, `unassigned_shards`: Various metrics about shard allocation.

This command will help confirm the cluster’s operational status and ensure everything is configured correctly.
