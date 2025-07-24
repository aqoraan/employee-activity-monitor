# 🚨 Emergency Stop Guide - System Monitor Applications

This guide provides comprehensive instructions for stopping the Mac System Monitor and Windows Employee Activity Monitor applications in case of issues.

## 📋 Table of Contents

1. [Quick Stop Commands](#quick-stop-commands)
2. [macOS Application Stop Methods](#macos-application-stop-methods)
3. [Windows Application Stop Methods](#windows-application-stop-methods)
4. [Emergency Stop Procedures](#emergency-stop-procedures)
5. [Troubleshooting](#troubleshooting)
6. [Safe Mode Operation](#safe-mode-operation)
7. [Log File Locations](#log-file-locations)
8. [Service Management](#service-management)

---

## ⚡ Quick Stop Commands

### **macOS:**
```bash
# Normal stop
pkill -f MacSystemMonitor

# Emergency stop
sudo pkill -9 -f MacSystemMonitor
```

### **Windows:**
```cmd
# Normal stop
taskkill /f /im EmployeeActivityMonitor.exe

# Emergency stop
sc stop EmployeeActivityMonitor
```

---

## 🍎 macOS Application Stop Methods

### **1. GUI Application Stop:**
```bash
# Kill the GUI app
pkill -f MacSystemMonitor

# More specific targeting
pkill -f "MacSystemMonitor"

# Check if it's running
ps aux | grep MacSystemMonitor
```

### **2. Background Process Stop:**
```bash
# Kill all instances
pkill -f MacSystemMonitor

# Kill by process ID (if known)
kill -9 <PID>

# Force kill all related processes
sudo pkill -9 -f MacSystemMonitor
```

### **3. Service Stop (if installed as service):**
```bash
# Stop the service
sudo launchctl unload /Library/LaunchDaemons/com.macsystemmonitor.plist

# Disable service
sudo launchctl disable system/com.macsystemmonitor

# Check service status
sudo launchctl list | grep macsystemmonitor
```

### **4. Complete Removal:**
```bash
# Stop and remove service
sudo launchctl unload /Library/LaunchDaemons/com.macsystemmonitor.plist
sudo rm /Library/LaunchDaemons/com.macsystemmonitor.plist

# Remove application files
sudo rm -rf /Applications/MacSystemMonitor.app
sudo rm -rf /var/log/mac-system-monitor.log*
```

---

## 🪟 Windows Application Stop Methods

### **1. GUI Application Stop:**
```cmd
# Kill the GUI app
taskkill /f /im EmployeeActivityMonitor.exe

# More specific targeting
taskkill /f /im "Employee Activity Monitor.exe"

# Check if it's running
tasklist | findstr EmployeeActivityMonitor
```

### **2. Background Process Stop:**
```cmd
# Kill by process name
taskkill /f /im EmployeeActivityMonitor.exe

# Kill by service name
sc stop EmployeeActivityMonitor

# Force kill
taskkill /f /im EmployeeActivityMonitor.exe /t
```

### **3. Service Stop (if installed as service):**
```cmd
# Stop the service
net stop EmployeeActivityMonitor

# Using PowerShell
Stop-Service -Name "EmployeeActivityMonitor"

# Disable service
sc config EmployeeActivityMonitor start= disabled

# Check service status
sc query EmployeeActivityMonitor
```

### **4. Complete Removal:**
```cmd
# Stop and remove service
sc stop EmployeeActivityMonitor
sc delete EmployeeActivityMonitor

# Remove application files
rmdir /s /q "C:\Program Files\EmployeeActivityMonitor"
del /f /q "C:\ProgramData\EmployeeActivityMonitor\logs\*"
```

---

## 🚨 Emergency Stop Procedures

### **macOS Emergency Stop:**
```bash
# Nuclear option - kill everything related
sudo pkill -9 -f "MacSystemMonitor"
sudo pkill -9 -f "system_monitor"

# Remove from startup
sudo launchctl unload /Library/LaunchDaemons/com.macsystemmonitor.plist
sudo rm /Library/LaunchDaemons/com.macsystemmonitor.plist

# Clear log files
sudo rm -f /var/log/mac-system-monitor.log*

# Reset configuration
sudo rm -f /etc/mac-system-monitor.conf
```

### **Windows Emergency Stop:**
```cmd
# Nuclear option
taskkill /f /im EmployeeActivityMonitor.exe
taskkill /f /im "Employee Activity Monitor.exe"

# Disable and stop service
sc config EmployeeActivityMonitor start= disabled
sc stop EmployeeActivityMonitor

# Clear log files
del /f /q "C:\ProgramData\EmployeeActivityMonitor\logs\*"

# Reset configuration
del /f /q "C:\ProgramData\EmployeeActivityMonitor\config.json"
```

---

## 🔍 Troubleshooting

### **Check if Application is Running:**

#### **macOS:**
```bash
# Check for running processes
ps aux | grep MacSystemMonitor

# Check for service
sudo launchctl list | grep macsystemmonitor

# Check log files
tail -f /var/log/mac-system-monitor.log
```

#### **Windows:**
```cmd
# Check for running processes
tasklist | findstr EmployeeActivityMonitor

# Check service status
sc query EmployeeActivityMonitor

# Check log files
type "C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log"
```

### **Common Issues and Solutions:**

#### **1. Application Won't Stop:**
```bash
# macOS
sudo pkill -9 -f MacSystemMonitor
sudo killall -9 MacSystemMonitor

# Windows
taskkill /f /im EmployeeActivityMonitor.exe /t
```

#### **2. Service Won't Stop:**
```bash
# macOS
sudo launchctl unload -w /Library/LaunchDaemons/com.macsystemmonitor.plist

# Windows
sc stop EmployeeActivityMonitor
sc delete EmployeeActivityMonitor
```

#### **3. Permission Issues:**
```bash
# macOS
sudo pkill -9 -f MacSystemMonitor
sudo chmod -R 755 /Applications/MacSystemMonitor.app

# Windows (Run as Administrator)
taskkill /f /im EmployeeActivityMonitor.exe
```

---

## 🛡️ Safe Mode Operation

### **macOS Safe Mode:**
```bash
# Run in test mode (no real monitoring)
./MacSystemMonitor --test-mode

# Or edit config to enable test mode
echo '{"testModeSettings": {"enableTestMode": true}}' > config.json
```

### **Windows Safe Mode:**
```cmd
# Run in test mode
EmployeeActivityMonitor.exe --test-mode

# Or edit config file to enable test mode
echo {"testModeSettings": {"enableTestMode": true}} > config.json
```

### **Test Mode Features:**
- ✅ No real system monitoring
- ✅ No USB blocking
- ✅ No file system changes
- ✅ Simulated events only
- ✅ Safe for testing

---

## 📁 Log File Locations

### **macOS Log Files:**
```bash
# Main log file
/var/log/mac-system-monitor.log

# Test app log file
/tmp/mac-system-monitor-test/enhanced-test.log

# Backup log files
/var/log/mac-system-monitor.log.1
```

### **Windows Log Files:**
```cmd
# Main log file
C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log

# Backup log files
C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log.1
```

### **View Log Files:**
```bash
# macOS
tail -f /var/log/mac-system-monitor.log
cat /var/log/mac-system-monitor.log

# Windows
type "C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log"
```

---

## ⚙️ Service Management

### **macOS Service Management:**
```bash
# Install service
sudo launchctl load /Library/LaunchDaemons/com.macsystemmonitor.plist

# Start service
sudo launchctl start com.macsystemmonitor

# Stop service
sudo launchctl stop com.macsystemmonitor

# Unload service
sudo launchctl unload /Library/LaunchDaemons/com.macsystemmonitor.plist

# Check service status
sudo launchctl list | grep macsystemmonitor
```

### **Windows Service Management:**
```cmd
# Install service
sc create EmployeeActivityMonitor binPath= "C:\Program Files\EmployeeActivityMonitor\EmployeeActivityMonitor.exe"

# Start service
net start EmployeeActivityMonitor

# Stop service
net stop EmployeeActivityMonitor

# Delete service
sc delete EmployeeActivityMonitor

# Check service status
sc query EmployeeActivityMonitor
```

---

## 📋 Quick Reference Table

| Action | macOS Command | Windows Command |
|--------|---------------|-----------------|
| **Check Status** | `ps aux \| grep MacSystemMonitor` | `tasklist \| findstr EmployeeActivityMonitor` |
| **Normal Stop** | `pkill -f MacSystemMonitor` | `taskkill /f /im EmployeeActivityMonitor.exe` |
| **Emergency Stop** | `sudo pkill -9 -f MacSystemMonitor` | `sc stop EmployeeActivityMonitor` |
| **Service Stop** | `sudo launchctl unload /Library/LaunchDaemons/com.macsystemmonitor.plist` | `net stop EmployeeActivityMonitor` |
| **View Logs** | `tail -f /var/log/mac-system-monitor.log` | `type "C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log"` |
| **Test Mode** | `./MacSystemMonitor --test-mode` | `EmployeeActivityMonitor.exe --test-mode` |

---

## ⚠️ Important Safety Notes

1. **Test Mode First**: Always test in safe/test mode before running production
2. **Backup Config**: Keep backups of your configuration files
3. **Log Files**: Check log files for issues before stopping
4. **Service Dependencies**: Be careful not to stop critical system services
5. **Permissions**: Some commands require administrator privileges
6. **Data Loss**: Emergency stops may cause data loss - use normal stop first

---

## 🆘 Getting Help

If you're still having issues:

1. **Check Log Files**: Look for error messages in the log files
2. **Test Mode**: Try running in test mode first
3. **Reboot**: Sometimes a system reboot helps
4. **Reinstall**: As a last resort, uninstall and reinstall the application

**Remember**: The applications are designed with safety in mind, but these commands will help you stop them if needed! 