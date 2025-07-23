using System;
using System.Collections.Generic;
using System.IO;
using System.Management;
using System.Net.Http;
using System.Threading.Tasks;
using System.Windows.Threading;
using Microsoft.Win32;
using Newtonsoft.Json;
using System.Linq;

namespace SystemMonitor
{
    public class MonitoringService
    {
        private readonly HttpClient _httpClient;
        private readonly AppConfig _config;
        private ManagementEventWatcher _usbWatcher;
        private ManagementEventWatcher _processWatcher;
        private List<FileSystemWatcher> _fileWatchers;
        private bool _isMonitoring;
        private UsbBlockingService _usbBlockingService;
        private GoogleSheetsManager _sheetsManager;
        private UninstallDetectionService _uninstallDetectionService;

        public event EventHandler<ActivityEventArgs> ActivityDetected;

        public MonitoringService(AppConfig config = null)
        {
            _httpClient = new HttpClient();
            _config = config ?? AppConfig.LoadFromFile();
            _fileWatchers = new List<FileSystemWatcher>();
            _isMonitoring = false;
            
            // Initialize USB blocking if enabled
            if (_config.UsbBlockingSettings.EnableUsbBlocking && 
                !string.IsNullOrEmpty(_config.UsbBlockingSettings.GoogleSheetsApiKey) &&
                !string.IsNullOrEmpty(_config.UsbBlockingSettings.GoogleSheetsSpreadsheetId))
            {
                _sheetsManager = new GoogleSheetsManager(
                    _config.UsbBlockingSettings.GoogleSheetsApiKey,
                    _config.UsbBlockingSettings.GoogleSheetsSpreadsheetId,
                    _config.UsbBlockingSettings.GoogleSheetsRange);
                
                _usbBlockingService = new UsbBlockingService(_sheetsManager, true);
                _usbBlockingService.UsbBlocked += OnUsbBlocked;
            }

            // Initialize uninstall detection
            if (!string.IsNullOrEmpty(_config.N8nWebhookUrl))
            {
                _uninstallDetectionService = new UninstallDetectionService(_config.N8nWebhookUrl);
                _uninstallDetectionService.InitializeUninstallDetection();
            }
        }

        public void StartMonitoring()
        {
            if (_isMonitoring) return;

            _isMonitoring = true;
            
            // Start USB blocking first if enabled
            if (_usbBlockingService != null)
            {
                _usbBlockingService.StartBlocking();
            }
            
            if (_config.MonitoringSettings.EnableUsbMonitoring)
                StartUsbMonitoring();
                
            if (_config.MonitoringSettings.EnableAppInstallationMonitoring || 
                _config.MonitoringSettings.EnableBlacklistedAppMonitoring)
                StartProcessMonitoring();
                
            if (_config.MonitoringSettings.EnableFileTransferMonitoring)
                StartFileTransferMonitoring();
                
            if (_config.MonitoringSettings.EnableNetworkMonitoring)
                StartNetworkMonitoring();
        }

        public void StopMonitoring()
        {
            if (!_isMonitoring) return;

            _isMonitoring = false;
            _usbWatcher?.Stop();
            _processWatcher?.Stop();
            _usbBlockingService?.StopBlocking();
            
            foreach (var watcher in _fileWatchers)
            {
                watcher?.Dispose();
            }
            _fileWatchers.Clear();
        }

        public async Task SendUninstallNotification()
        {
            if (_uninstallDetectionService != null)
            {
                await _uninstallDetectionService.SendUninstallNotification();
            }
        }

        private void OnUsbBlocked(object sender, UsbBlockingEventArgs e)
        {
            var activity = new ActivityEventArgs
            {
                Type = ActivityType.UsbBlocked,
                Description = $"USB device blocked: {e.DeviceId} - {e.Reason}",
                Timestamp = e.Timestamp,
                Severity = ActivitySeverity.High,
                Details = new Dictionary<string, string>
                {
                    ["DeviceID"] = e.DeviceId,
                    ["Reason"] = e.Reason,
                    ["Blocked"] = e.Blocked.ToString()
                }
            };

            OnActivityDetected(activity);
        }

        private void StartUsbMonitoring()
        {
            try
            {
                var query = new WqlEventQuery("SELECT * FROM Win32_DeviceChangeEvent WHERE EventType = 2 or EventType = 3");
                _usbWatcher = new ManagementEventWatcher(query);
                _usbWatcher.EventArrived += (sender, e) =>
                {
                    var eventType = e.NewEvent["EventType"];
                    var deviceId = e.NewEvent["DeviceID"];
                    
                    var activity = new ActivityEventArgs
                    {
                        Type = ActivityType.UsbDrive,
                        Description = $"USB device {(eventType.ToString() == "2" ? "connected" : "disconnected")}: {deviceId}",
                        Timestamp = DateTime.Now,
                        Severity = ActivitySeverity.Medium,
                        Details = new Dictionary<string, string>
                        {
                            ["EventType"] = eventType?.ToString() ?? "Unknown",
                            ["DeviceID"] = deviceId?.ToString() ?? "Unknown"
                        }
                    };

                    OnActivityDetected(activity);
                };
                _usbWatcher.Start();
            }
            catch (Exception ex)
            {
                OnActivityDetected(new ActivityEventArgs
                {
                    Type = ActivityType.System,
                    Description = $"USB monitoring error: {ex.Message}",
                    Timestamp = DateTime.Now,
                    Severity = ActivitySeverity.High
                });
            }
        }

        private void StartProcessMonitoring()
        {
            try
            {
                var query = new WqlEventQuery("SELECT * FROM Win32_ProcessStartTrace");
                _processWatcher = new ManagementEventWatcher(query);
                _processWatcher.EventArrived += (sender, e) =>
                {
                    var processName = e.NewEvent["ProcessName"]?.ToString();
                    var processId = e.NewEvent["ProcessID"]?.ToString();
                    var commandLine = e.NewEvent["CommandLine"]?.ToString();

                    if (!string.IsNullOrEmpty(processName))
                    {
                        // Check for blacklisted applications
                        if (_config.MonitoringSettings.EnableBlacklistedAppMonitoring && 
                            IsBlacklistedApp(processName))
                        {
                            var activity = new ActivityEventArgs
                            {
                                Type = ActivityType.BlacklistedApp,
                                Description = $"Blacklisted application detected: {processName} (PID: {processId})",
                                Timestamp = DateTime.Now,
                                Severity = ActivitySeverity.High,
                                Details = new Dictionary<string, string>
                                {
                                    ["ProcessName"] = processName,
                                    ["ProcessID"] = processId,
                                    ["CommandLine"] = commandLine
                                }
                            };

                            OnActivityDetected(activity);
                        }

                        // Check for installation activities
                        if (_config.MonitoringSettings.EnableAppInstallationMonitoring && 
                            IsInstallationProcess(processName, commandLine))
                        {
                            var activity = new ActivityEventArgs
                            {
                                Type = ActivityType.AppInstallation,
                                Description = $"Application installation detected: {processName}",
                                Timestamp = DateTime.Now,
                                Severity = ActivitySeverity.Medium,
                                Details = new Dictionary<string, string>
                                {
                                    ["ProcessName"] = processName,
                                    ["ProcessID"] = processId,
                                    ["CommandLine"] = commandLine
                                }
                            };

                            OnActivityDetected(activity);
                        }
                    }
                };
                _processWatcher.Start();
            }
            catch (Exception ex)
            {
                OnActivityDetected(new ActivityEventArgs
                {
                    Type = ActivityType.System,
                    Description = $"Process monitoring error: {ex.Message}",
                    Timestamp = DateTime.Now,
                    Severity = ActivitySeverity.High
                });
            }
        }

        private void StartFileTransferMonitoring()
        {
            try
            {
                // Monitor common USB drive letters
                var driveLetters = new[] { "D:", "E:", "F:", "G:", "H:", "I:", "J:", "K:", "L:", "M:", "N:", "O:", "P:" };
                
                foreach (var drive in driveLetters)
                {
                    if (Directory.Exists(drive))
                    {
                        var watcher = new FileSystemWatcher(drive)
                        {
                            IncludeSubdirectories = true,
                            EnableRaisingEvents = true,
                            NotifyFilter = NotifyFilters.FileName | NotifyFilters.DirectoryName | NotifyFilters.Size
                        };

                        watcher.Created += (sender, e) =>
                        {
                            var activity = new ActivityEventArgs
                            {
                                Type = ActivityType.FileTransfer,
                                Description = $"File created on USB drive: {e.FullPath}",
                                Timestamp = DateTime.Now,
                                Severity = ActivitySeverity.Medium,
                                Details = new Dictionary<string, string>
                                {
                                    ["FilePath"] = e.FullPath,
                                    ["Drive"] = drive,
                                    ["FileSize"] = GetFileSize(e.FullPath),
                                    ["EventType"] = "Created"
                                }
                            };

                            OnActivityDetected(activity);
                        };

                        watcher.Changed += (sender, e) =>
                        {
                            var activity = new ActivityEventArgs
                            {
                                Type = ActivityType.FileTransfer,
                                Description = $"File modified on USB drive: {e.FullPath}",
                                Timestamp = DateTime.Now,
                                Severity = ActivitySeverity.Low,
                                Details = new Dictionary<string, string>
                                {
                                    ["FilePath"] = e.FullPath,
                                    ["Drive"] = drive,
                                    ["FileSize"] = GetFileSize(e.FullPath),
                                    ["EventType"] = "Modified"
                                }
                            };

                            OnActivityDetected(activity);
                        };

                        watcher.Deleted += (sender, e) =>
                        {
                            var activity = new ActivityEventArgs
                            {
                                Type = ActivityType.FileTransfer,
                                Description = $"File deleted from USB drive: {e.FullPath}",
                                Timestamp = DateTime.Now,
                                Severity = ActivitySeverity.Low,
                                Details = new Dictionary<string, string>
                                {
                                    ["FilePath"] = e.FullPath,
                                    ["Drive"] = drive,
                                    ["EventType"] = "Deleted"
                                }
                            };

                            OnActivityDetected(activity);
                        };

                        _fileWatchers.Add(watcher);
                    }
                }
            }
            catch (Exception ex)
            {
                OnActivityDetected(new ActivityEventArgs
                {
                    Type = ActivityType.System,
                    Description = $"File transfer monitoring error: {ex.Message}",
                    Timestamp = DateTime.Now,
                    Severity = ActivitySeverity.High
                });
            }
        }

        private void StartNetworkMonitoring()
        {
            // Monitor network connections using WMI
            try
            {
                var query = new WqlEventQuery("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = true");
                var networkWatcher = new ManagementEventWatcher(query);
                networkWatcher.EventArrived += (sender, e) =>
                {
                    // Check for suspicious network activity
                    var activity = new ActivityEventArgs
                    {
                        Type = ActivityType.NetworkActivity,
                        Description = "Network configuration change detected",
                        Timestamp = DateTime.Now,
                        Severity = ActivitySeverity.Medium,
                        Details = new Dictionary<string, string>
                        {
                            ["EventType"] = "NetworkConfigurationChange"
                        }
                    };

                    OnActivityDetected(activity);
                };
                networkWatcher.Start();
            }
            catch (Exception ex)
            {
                OnActivityDetected(new ActivityEventArgs
                {
                    Type = ActivityType.System,
                    Description = $"Network monitoring error: {ex.Message}",
                    Timestamp = DateTime.Now,
                    Severity = ActivitySeverity.High
                });
            }
        }

        private bool IsBlacklistedApp(string processName)
        {
            return _config.BlacklistedApps.Contains(processName.ToLower());
        }

        private bool IsInstallationProcess(string processName, string commandLine)
        {
            var installKeywords = new[] { "install", "setup", "msi", "exe", "installer", "uninstall" };
            var processNameLower = processName.ToLower();
            var commandLineLower = commandLine?.ToLower() ?? "";

            return installKeywords.Any(keyword => 
                processNameLower.Contains(keyword) || commandLineLower.Contains(keyword));
        }

        private string GetFileSize(string filePath)
        {
            try
            {
                if (File.Exists(filePath))
                {
                    var fileInfo = new FileInfo(filePath);
                    return fileInfo.Length.ToString();
                }
                return "Unknown";
            }
            catch
            {
                return "Unknown";
            }
        }

        public async Task SendToN8n(ActivityEventArgs activity)
        {
            if (string.IsNullOrEmpty(_config.N8nWebhookUrl) || !_config.MonitoringSettings.SendToN8n) 
                return;

            for (int attempt = 1; attempt <= _config.MonitoringSettings.N8nRetryAttempts; attempt++)
            {
                try
                {
                    var payload = new
                    {
                        timestamp = activity.Timestamp.ToString("yyyy-MM-dd HH:mm:ss"),
                        type = activity.Type.ToString(),
                        description = activity.Description,
                        severity = activity.Severity.ToString(),
                        details = activity.Details,
                        computer = Environment.MachineName,
                        user = Environment.UserName,
                        config = new
                        {
                            logLevel = _config.MonitoringSettings.LogLevel,
                            maxLogEntries = _config.MonitoringSettings.MaxLogEntries
                        }
                    };

                    var json = JsonConvert.SerializeObject(payload);
                    var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");
                    
                    var response = await _httpClient.PostAsync(_config.N8nWebhookUrl, content);
                    
                    if (!response.IsSuccessStatusCode)
                    {
                        throw new Exception($"HTTP {response.StatusCode}: {response.ReasonPhrase}");
                    }

                    // Success, break out of retry loop
                    break;
                }
                catch (Exception ex)
                {
                    if (attempt == _config.MonitoringSettings.N8nRetryAttempts)
                    {
                        OnActivityDetected(new ActivityEventArgs
                        {
                            Type = ActivityType.System,
                            Description = $"Failed to send to N8N after {attempt} attempts: {ex.Message}",
                            Timestamp = DateTime.Now,
                            Severity = ActivitySeverity.High
                        });
                    }
                    else
                    {
                        // Wait before retry
                        await Task.Delay(_config.MonitoringSettings.N8nRetryDelayMs);
                    }
                }
            }
        }

        protected virtual void OnActivityDetected(ActivityEventArgs e)
        {
            ActivityDetected?.Invoke(this, e);
        }

        public void Dispose()
        {
            StopMonitoring();
            _httpClient?.Dispose();
            _usbWatcher?.Dispose();
            _processWatcher?.Dispose();
            _usbBlockingService?.Dispose();
            _sheetsManager?.Dispose();
            _uninstallDetectionService?.Dispose();
            
            foreach (var watcher in _fileWatchers)
            {
                watcher?.Dispose();
            }
        }
    }

    public class ActivityEventArgs : EventArgs
    {
        public ActivityType Type { get; set; }
        public string Description { get; set; }
        public DateTime Timestamp { get; set; }
        public ActivitySeverity Severity { get; set; }
        public Dictionary<string, string> Details { get; set; } = new Dictionary<string, string>();
    }

    public enum ActivityType
    {
        UsbDrive,
        FileTransfer,
        AppInstallation,
        BlacklistedApp,
        NetworkActivity,
        System,
        UsbBlocked
    }

    public enum ActivitySeverity
    {
        Low,
        Medium,
        High,
        Critical
    }
} 