# Security Features - Employee Activity Monitor

## 🔐 Administrative Privileges & Protection

### Overview
The Employee Activity Monitor includes comprehensive security features to prevent unauthorized access, modification, or uninstallation. The application requires administrative privileges and integrates with Google Workspace for enhanced security validation.

## 🛡️ Security Features

### 1. Administrative Privileges Required
- **Application Level**: All monitoring functions require administrative privileges
- **Service Installation**: Windows Service installation requires admin rights
- **Configuration Access**: Configuration files are protected from non-admin users
- **Registry Access**: Registry modifications require administrative access

### 2. Auto-Start Protection
- **Windows Service**: Runs as a Windows Service with automatic startup
- **Registry Startup**: Added to Windows startup registry
- **Service Account**: Runs under Local System account for maximum privileges
- **Automatic Recovery**: Service automatically restarts if stopped

### 3. Configuration Protection
- **File Permissions**: Configuration files are set to read-only for non-admins
- **Registry Protection**: Registry keys are protected with restricted access
- **Encrypted Storage**: Sensitive configuration data is encrypted
- **Access Control**: Only administrators can modify configuration

### 4. Uninstallation Prevention
- **Service Protection**: Windows Service prevents easy removal
- **Registry Entries**: Multiple registry entries make removal difficult
- **File Protection**: Executable files are protected from deletion
- **Windows Defender**: Added to Windows Defender exclusions

### 5. Google Workspace Admin Integration
- **Admin Validation**: Verifies user is Google Workspace administrator
- **API Integration**: Uses Google Admin SDK for validation
- **Token Security**: Secure token-based authentication
- **Fallback Protection**: Falls back to local admin check if Google API unavailable

## 🚀 Installation & Deployment

### Secure Deployment
```powershell
# Run as Administrator
.\deploy-secure.ps1 -InstallAsService -GoogleWorkspaceAdmin "admin@yourcompany.com" -GoogleWorkspaceToken "your-token"
```

### Service Installation
```powershell
# Install as Windows Service
SystemMonitor.exe --install
```

### Google Workspace Setup
1. **Create Service Account**:
   - Go to Google Cloud Console
   - Create a new project
   - Enable Admin SDK API
   - Create service account credentials

2. **Generate Access Token**:
   ```bash
   # Using Google Cloud CLI
   gcloud auth application-default login
   gcloud auth print-access-token
   ```

3. **Configure Application**:
   ```json
   {
     "securitySettings": {
       "googleWorkspaceAdmin": "admin@yourcompany.com",
       "googleWorkspaceToken": "your-access-token",
       "requireGoogleWorkspaceAdmin": true
     }
   }
   ```

## 🔧 Configuration Security

### File Permissions
```powershell
# Set configuration file permissions
$acl = Get-Acl "config.json"
$acl.SetAccessRuleProtection($true, $false)
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "Allow")
$acl.AddAccessRule($adminRule)
Set-Acl -Path "config.json" -AclObject $acl
```

### Registry Protection
```powershell
# Create protected registry entries
$registryPath = "HKLM:\SOFTWARE\EmployeeActivityMonitor"
New-Item -Path $registryPath -Force
Set-ItemProperty -Path $registryPath -Name "Protected" -Value "true"
Set-ItemProperty -Path $registryPath -Name "RequiresAdmin" -Value "true"
```

## 🛠️ Management Commands

### Service Management
```batch
# Start service
manage-service.bat start

# Stop service
manage-service.bat stop

# Check status
manage-service.bat status
```

### Admin Validation
```bash
# Validate Google Workspace admin
SystemMonitor.exe --validate-admin "admin@yourcompany.com" "your-token"
```

### Secure Uninstallation
```batch
# Only for authorized administrators
uninstall-secure.bat
```

## 📋 Security Checklist

### Pre-Deployment
- [ ] Verify administrative privileges
- [ ] Set up Google Workspace admin account
- [ ] Generate API access token
- [ ] Configure Windows Defender exclusions
- [ ] Test service installation

### Post-Deployment
- [ ] Verify service is running
- [ ] Test configuration protection
- [ ] Validate admin access
- [ ] Monitor Windows Event Logs
- [ ] Test uninstallation prevention

### Ongoing Security
- [ ] Monitor service status
- [ ] Review security logs
- [ ] Update Google Workspace tokens
- [ ] Verify file permissions
- [ ] Check registry protection

## 🔍 Monitoring & Logging

### Windows Event Logs
- **Application Log**: General application events
- **Security Log**: Security-related events
- **System Log**: Service and system events

### Security Events Logged
- Application startup/shutdown
- Configuration changes
- Admin access attempts
- Service status changes
- Uninstallation attempts

### Log Locations
```
Event Viewer > Windows Logs > Application > EmployeeActivityMonitor
Event Viewer > Windows Logs > Security > EmployeeActivityMonitor
```

## 🚨 Troubleshooting

### Common Issues

1. **"Administrative privileges required"**
   - Right-click application → "Run as administrator"
   - Check User Account Control settings
   - Verify user is in Administrators group

2. **"Google Workspace admin validation failed"**
   - Verify API token is valid
   - Check Google Workspace admin permissions
   - Ensure Admin SDK API is enabled

3. **"Service installation failed"**
   - Run PowerShell as Administrator
   - Check Windows Service permissions
   - Verify .NET Framework installation

4. **"Configuration access denied"**
   - Check file permissions
   - Verify registry access
   - Run as Administrator

### Debug Commands
```powershell
# Check service status
Get-Service -Name "EmployeeActivityMonitor"

# View application logs
Get-EventLog -LogName Application -Source "EmployeeActivityMonitor"

# Check file permissions
Get-Acl "config.json" | Format-List

# Verify registry entries
Get-ItemProperty "HKLM:\SOFTWARE\EmployeeActivityMonitor"
```

## 🔒 Compliance & Best Practices

### Data Protection
- All monitoring data is encrypted
- Configuration files are protected
- Registry entries are secured
- Log files are access-controlled

### Access Control
- Administrative privileges required
- Google Workspace admin validation
- Service account authentication
- Multi-factor protection

### Audit Trail
- Comprehensive event logging
- Security event tracking
- Configuration change logging
- Access attempt monitoring

### Recovery Procedures
- Automatic service restart
- Configuration backup
- Registry protection
- File permission restoration

## ⚠️ Important Notes

### Legal Compliance
- Ensure compliance with local privacy laws
- Inform employees about monitoring
- Implement appropriate data retention
- Follow company security policies

### Security Considerations
- Keep Google Workspace tokens secure
- Regularly update access credentials
- Monitor for unauthorized access
- Implement incident response procedures

### Maintenance
- Regular security updates
- Configuration backups
- Service health monitoring
- Performance optimization

---

**Note**: This application implements enterprise-grade security features. Ensure proper authorization and compliance with organizational policies before deployment. 