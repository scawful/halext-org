# Emergency Server Recovery Guide

**When your Ubuntu server is too slow to SSH into**

## 🚨 Quick Summary

Your server is likely experiencing one of these issues:
1. **Ollama consuming all memory** (most likely)
2. **Docker/OpenWebUI memory leak**
3. **Disk full or I/O bottleneck**
4. **Too many concurrent connections**

---

## Option 1: Automated Emergency Cleanup (Recommended)

### A. Using the emergency cleanup script

```bash
cd /Users/scawful/Code/halext-org

# Edit the script first with your credentials:
nano scripts/emergency-ubuntu-cleanup.sh

# Update these lines:
# SERVER_USER="your-username"
# SERVER_HOST="your-server-ip"
# SSH_PORT="22"

# Install sshpass if needed (macOS):
brew install hudochenkov/sshpass/sshpass

# Run the script
./scripts/emergency-ubuntu-cleanup.sh
```

**What it does:**
- ✅ Connects with aggressive timeouts (won't hang)
- ✅ Kills Ollama service immediately
- ✅ Restarts Docker
- ✅ Clears system caches
- ✅ Kills zombie processes
- ✅ Restarts critical services
- ✅ Offers to reboot if needed

### B. Using expect script (if sshpass fails)

```bash
# Edit credentials in the file first:
nano scripts/emergency-kill-ollama.sh

# Update these lines:
# set server_user "your-username"
# set server_host "your-server-ip"
# set ssh_password "your-password"

# Run it:
./scripts/emergency-kill-ollama.sh
```

---

## Option 2: One-Liner Commands

If the scripts don't work, try these manual one-liners:

### Kill Ollama immediately:
```bash
ssh -o ConnectTimeout=10 user@server-ip "sudo pkill -9 ollama"
```

### Restart Docker (restarts OpenWebUI):
```bash
ssh -o ConnectTimeout=10 user@server-ip "sudo systemctl restart docker"
```

### Clear caches and free memory:
```bash
ssh -o ConnectTimeout=10 user@server-ip "sudo sync && sudo sysctl -w vm.drop_caches=3"
```

### Check current status:
```bash
ssh -o ConnectTimeout=10 user@server-ip "uptime && free -h && df -h"
```

### Nuclear option - restart server:
```bash
ssh -o ConnectTimeout=10 user@server-ip "sudo reboot"
```

---

## Option 3: Using your hosting provider's console

If SSH completely fails:

1. **Log into your hosting provider** (DigitalOcean, Linode, Vultr, etc.)
2. **Access the VNC/Console** (usually under "Access" or "Console")
3. **Login via console** (you'll see a terminal)
4. **Run these commands:**

```bash
# Check what's consuming resources
top

# Press 'M' to sort by memory
# Press 'q' to quit

# Kill Ollama if it's at the top
sudo pkill -9 ollama

# Check memory
free -h

# Restart Docker
sudo systemctl restart docker

# Check if things improved
uptime
```

---

## Option 4: Provider Control Panel Reboot

As a last resort:

1. Log into your hosting provider's control panel
2. Find your VM/droplet
3. Click "Power" → "Reboot" or "Hard Reset"
4. Wait 1-2 minutes for it to come back online

---

## 🔧 After Recovery - Prevent This Again

Once you regain access:

### 1. Limit Ollama memory usage

Edit `/etc/systemd/system/ollama.service`:

```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_NUM_PARALLEL=1"
# Limit to 1GB memory (adjust as needed)
MemoryMax=1G
MemoryHigh=800M
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

### 2. Monitor resource usage

Install and use `htop`:
```bash
sudo apt install htop
htop
```

### 3. Set up alerts

Create a cron job to alert on high memory:
```bash
crontab -e

# Add this line (replace with your email):
*/5 * * * * [ $(free | grep Mem | awk '{print ($3/$2)*100}' | cut -d. -f1) -gt 80 ] && echo "High memory usage on server" | mail -s "Server Alert" your@email.com
```

### 4. Consider moving Ollama off the VM

Since your VM only has 2GB RAM, it's better to:
- ✅ Run Ollama on your Mac M1 (32GB RAM)
- ✅ Run Ollama on your Windows PC (16GB GPU)
- ✅ Have Ubuntu VM just proxy to those nodes

This is exactly what we built the Admin Panel for!

---

## 📊 Understanding the Problem

### Why Ollama eats all your memory:

With only **2GB RAM** on your Ubuntu VM:
- Ollama alone needs ~1GB for runtime
- Even small models (7B) need 4-8GB RAM
- OpenWebUI Docker container: ~500MB
- System + Nginx + Backend: ~500MB
- **Total needed:** 2-9GB
- **You have:** 2GB

### The Solution:

**Don't run models ON the Ubuntu server!**

Instead:
1. Ubuntu VM runs the web interface and backend
2. Mac M1 serves models via Ollama (you already have this)
3. Windows PC serves models too (when ready)
4. Admin panel manages all nodes

---

## 🎯 Next Steps After Recovery

1. **Stop Ollama on Ubuntu:**
   ```bash
   sudo systemctl stop ollama
   sudo systemctl disable ollama
   ```

2. **Deploy the new admin panel code** we created

3. **Set up port forwarding** on your router for Mac

4. **Add Mac as a client** in the admin panel

5. **Let your powerful machines handle AI** while Ubuntu just coordinates

---

## 📞 Emergency Contacts

- **Hosting Provider Support:** Check your provider's support page
- **Console Access:** Usually at `https://cloud.provider.com/console`
- **SSH with timeout:** `ssh -o ConnectTimeout=10 user@host`

---

## ⚡ Quick Reference Card

| Problem | Command |
|---------|---------|
| Kill Ollama | `ssh user@host "sudo pkill -9 ollama"` |
| Restart Docker | `ssh user@host "sudo systemctl restart docker"` |
| Clear cache | `ssh user@host "sudo sysctl -w vm.drop_caches=3"` |
| Check status | `ssh user@host "uptime && free -h"` |
| Reboot | `ssh user@host "sudo reboot"` |

---

**Remember:** Your 2GB VM should coordinate, not compute. Let the Mac and Windows do the heavy lifting!
