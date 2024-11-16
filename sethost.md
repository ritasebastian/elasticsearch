

#### **a. Set a New Hostname**
```bash
sudo hostnamectl set-hostname new-hostname
```
- This command sets the hostname of the system to `new-hostname`.
- The change is immediate and affects the transient hostname (current session) and persistent hostname (survives reboots).

#### **b. Restart the `systemd-hostnamed` Service**
```bash
sudo systemctl restart systemd-hostnamed
```
- This restarts the `systemd-hostnamed` service to ensure the hostname change is fully applied across the system.

---

### **2. Verify the Hostname**

After running these commands, verify the hostname:

1. **Using `hostnamectl`**:
   ```bash
   hostnamectl
   ```
   Look for the line `Static hostname` to confirm the change.

2. **Using `hostname`**:
   ```bash
   hostname
   ```

3. **Check `/etc/hostname`**:
   ```bash
   cat /etc/hostname
   ```

---

### **3. Update `/etc/hosts` (Recommended)**

To avoid potential network or application issues, update the `/etc/hosts` file to map the new hostname to `127.0.0.1`:

1. Open `/etc/hosts` for editing:
   ```bash
   sudo vi /etc/hosts
   ```

2. Update the file to include the new hostname:
   ```plaintext
   127.0.0.1   localhost
   127.0.0.1   new-hostname
   ```

3. Save and exit.

---

### **4. Reboot (Optional)**
While not always necessary, rebooting ensures the hostname change is fully applied across all processes:
```bash
sudo reboot
```

---

