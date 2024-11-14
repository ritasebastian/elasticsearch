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
