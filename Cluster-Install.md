
### **1. Prerequisites**

- Ensure the operating system is supported (RHEL, CentOS, Fedora, Amazon Linux, Debian, or Ubuntu).
- You need `sudo` or root privileges.
- Ensure your system is up-to-date:
  ```bash
  sudo dnf update -y
  ```

---

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

