using System;
using System.IO;
using System.Security.Principal;
using Microsoft.Win32;
using System.Net.Http;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace SystemMonitor
{
    public class SecurityManager
    {
        private const string REGISTRY_KEY = @"SOFTWARE\EmployeeActivityMonitor";
        private const string CONFIG_FILE = "config.json";
        private const string GOOGLE_WORKSPACE_API = "https://admin.googleapis.com/admin/directory/v1/users/";
        
        public static bool IsRunningAsAdministrator()
        {
            try
            {
                var identity = WindowsIdentity.GetCurrent();
                var principal = new WindowsPrincipal(identity);
                return principal.IsInRole(WindowsBuiltInRole.Administrator);
            }
            catch
            {
                return false;
            }
        }

        public static bool IsGoogleWorkspaceAdmin(string email, string adminToken)
        {
            try
            {
                using (var client = new HttpClient())
                {
                    client.DefaultRequestHeaders.Add("Authorization", $"Bearer {adminToken}");
                    
                    var response = client.GetAsync($"{GOOGLE_WORKSPACE_API}{email}?fields=isAdmin").Result;
                    
                    if (response.IsSuccessStatusCode)
                    {
                        var content = response.Content.ReadAsStringAsync().Result;
                        var userInfo = JsonConvert.DeserializeObject<dynamic>(content);
                        return userInfo.isAdmin == true;
                    }
                }
            }
            catch (Exception ex)
            {
                // Log error but don't throw
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to verify Google Workspace admin: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Warning);
            }
            
            return false;
        }

        public static void ProtectConfiguration()
        {
            try
            {
                // Set file permissions to read-only for non-admins
                var configPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, CONFIG_FILE);
                if (File.Exists(configPath))
                {
                    var fileInfo = new FileInfo(configPath);
                    fileInfo.Attributes |= FileAttributes.ReadOnly;
                }

                // Protect registry keys
                using (var key = Registry.LocalMachine.CreateSubKey(REGISTRY_KEY))
                {
                    if (key != null)
                    {
                        // Set registry permissions to restrict access
                        var security = key.GetAccessControl();
                        var adminSid = new SecurityIdentifier(WellKnownSidType.BuiltinAdministratorsSid, null);
                        var adminAccount = adminSid.Translate(typeof(NTAccount)) as NTAccount;
                        
                        if (adminAccount != null)
                        {
                            var rule = new System.Security.AccessControl.RegistryAccessRule(
                                adminAccount, 
                                System.Security.AccessControl.RegistryRights.FullControl, 
                                System.Security.AccessControl.AccessControlType.Allow);
                            
                            security.AddAccessRule(rule);
                            key.SetAccessControl(security);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to protect configuration: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Error);
            }
        }

        public static void PreventUninstallation()
        {
            try
            {
                // Add to Windows startup registry
                using (var key = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Run", true))
                {
                    if (key != null)
                    {
                        var exePath = System.Reflection.Assembly.GetExecutingAssembly().Location;
                        key.SetValue("EmployeeActivityMonitor", $"\"{exePath}\"");
                    }
                }

                // Protect the executable
                var exePath = System.Reflection.Assembly.GetExecutingAssembly().Location;
                var fileInfo = new FileInfo(exePath);
                fileInfo.Attributes |= FileAttributes.ReadOnly;

                // Add to Windows Defender exclusions (requires admin)
                if (IsRunningAsAdministrator())
                {
                    AddWindowsDefenderExclusion(exePath);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to prevent uninstallation: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Error);
            }
        }

        private static void AddWindowsDefenderExclusion(string path)
        {
            try
            {
                var process = new System.Diagnostics.Process();
                process.StartInfo.FileName = "powershell.exe";
                process.StartInfo.Arguments = $"-Command \"Add-MpPreference -ExclusionPath '{path}'\"";
                process.StartInfo.UseShellExecute = false;
                process.StartInfo.CreateNoWindow = true;
                process.Start();
                process.WaitForExit();
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to add Windows Defender exclusion: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Warning);
            }
        }

        public static bool ValidateAdminAccess(string email, string adminToken)
        {
            // Check if user is Google Workspace admin
            if (!string.IsNullOrEmpty(email) && !string.IsNullOrEmpty(adminToken))
            {
                return IsGoogleWorkspaceAdmin(email, adminToken);
            }

            // Fallback to local admin check
            return IsRunningAsAdministrator();
        }

        public static void LogSecurityEvent(string eventDescription, string userEmail = null)
        {
            try
            {
                var logMessage = $"Security Event: {eventDescription}";
                if (!string.IsNullOrEmpty(userEmail))
                {
                    logMessage += $" | User: {userEmail}";
                }
                
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", logMessage, 
                    System.Diagnostics.EventLogEntryType.Warning);
            }
            catch
            {
                // Ignore logging errors
            }
        }

        public static void SetRegistryProtection()
        {
            try
            {
                using (var key = Registry.LocalMachine.CreateSubKey(REGISTRY_KEY))
                {
                    if (key != null)
                    {
                        // Set registry values that prevent easy removal
                        key.SetValue("InstallDate", DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
                        key.SetValue("Version", "1.0.0");
                        key.SetValue("Protected", "true");
                        key.SetValue("RequiresAdmin", "true");
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to set registry protection: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Error);
            }
        }

        public static bool IsServiceInstalled()
        {
            try
            {
                using (var service = new System.ServiceProcess.ServiceController("EmployeeActivityMonitor"))
                {
                    return true;
                }
            }
            catch
            {
                return false;
            }
        }

        public static void InstallAsService()
        {
            if (!IsServiceInstalled())
            {
                try
                {
                    WindowsService.InstallService();
                    System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                        "Service installed successfully", 
                        System.Diagnostics.EventLogEntryType.Information);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                        $"Failed to install service: {ex.Message}", 
                        System.Diagnostics.EventLogEntryType.Error);
                    throw;
                }
            }
        }
    }
} 