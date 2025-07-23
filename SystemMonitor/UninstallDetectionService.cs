using System;
using System.Threading.Tasks;
using System.Net.Http;
using Newtonsoft.Json;
using Microsoft.Win32;
using System.IO;

namespace SystemMonitor
{
    public class UninstallDetectionService
    {
        private readonly string _n8nWebhookUrl;
        private readonly HttpClient _httpClient;
        private readonly string _registryKey = @"SOFTWARE\EmployeeActivityMonitor";
        private readonly string _uninstallFlagFile;

        public UninstallDetectionService(string n8nWebhookUrl)
        {
            _n8nWebhookUrl = n8nWebhookUrl;
            _httpClient = new HttpClient();
            _uninstallFlagFile = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), 
                "EmployeeActivityMonitor", "uninstall_detected.flag");
        }

        public void InitializeUninstallDetection()
        {
            try
            {
                // Create uninstall flag file to detect uninstallation
                var directory = Path.GetDirectoryName(_uninstallFlagFile);
                if (!Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory);
                }

                // Write current process info to flag file
                var processInfo = new
                {
                    ProcessId = Environment.ProcessId,
                    StartTime = DateTime.Now,
                    InstallationPath = System.Reflection.Assembly.GetExecutingAssembly().Location
                };

                File.WriteAllText(_uninstallFlagFile, JsonConvert.SerializeObject(processInfo));

                // Set up registry monitoring for uninstall detection
                MonitorRegistryForUninstall();

                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    "Uninstall detection initialized", 
                    System.Diagnostics.EventLogEntryType.Information);
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to initialize uninstall detection: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Error);
            }
        }

        private void MonitorRegistryForUninstall()
        {
            try
            {
                // Monitor registry key for changes (uninstall process)
                using (var key = Registry.LocalMachine.CreateSubKey(_registryKey))
                {
                    if (key != null)
                    {
                        key.SetValue("LastAccess", DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
                        key.SetValue("ProcessId", Environment.ProcessId.ToString());
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to monitor registry for uninstall: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Warning);
            }
        }

        public async Task SendUninstallNotification()
        {
            try
            {
                var deviceInfo = DeviceInfoManager.GetDeviceInfo();
                
                var uninstallData = new
                {
                    eventType = "UninstallDetected",
                    timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
                    severity = "Critical",
                    computer = deviceInfo.ComputerName,
                    user = deviceInfo.UserName,
                    deviceInfo = new
                    {
                        serialNumber = deviceInfo.SerialNumber,
                        primaryMacAddress = deviceInfo.PrimaryMacAddress,
                        allMacAddresses = deviceInfo.MacAddresses,
                        biosSerialNumber = deviceInfo.BiosSerialNumber,
                        motherboardSerialNumber = deviceInfo.MotherboardSerialNumber,
                        windowsProductId = deviceInfo.WindowsProductId,
                        installationPath = deviceInfo.InstallationPath,
                        deviceFingerprint = DeviceInfoManager.GetDeviceFingerprint()
                    },
                    uninstallDetails = new
                    {
                        processId = Environment.ProcessId,
                        processName = System.Diagnostics.Process.GetCurrentProcess().ProcessName,
                        commandLine = Environment.CommandLine,
                        uninstallTime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
                    }
                };

                var json = JsonConvert.SerializeObject(uninstallData);
                var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

                var response = await _httpClient.PostAsync(_n8nWebhookUrl, content);
                
                if (response.IsSuccessStatusCode)
                {
                    System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                        "Uninstall notification sent successfully", 
                        System.Diagnostics.EventLogEntryType.Information);
                }
                else
                {
                    System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                        $"Failed to send uninstall notification: {response.StatusCode}", 
                        System.Diagnostics.EventLogEntryType.Warning);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Error sending uninstall notification: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Error);
            }
        }

        public void CleanupUninstallDetection()
        {
            try
            {
                // Remove uninstall flag file
                if (File.Exists(_uninstallFlagFile))
                {
                    File.Delete(_uninstallFlagFile);
                }

                // Clean up registry entries
                try
                {
                    Registry.LocalMachine.DeleteSubKey(_registryKey, false);
                }
                catch
                {
                    // Ignore if key doesn't exist
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Error cleaning up uninstall detection: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Warning);
            }
        }

        public void Dispose()
        {
            _httpClient?.Dispose();
        }
    }
} 