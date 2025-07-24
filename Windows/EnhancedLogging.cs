using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management;
using System.Net.NetworkInformation;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Win32;

namespace EmployeeActivityMonitor
{
    // MARK: - Enhanced Logging System
    
    public class EnhancedLogging
    {
        private static readonly EnhancedLogging _instance = new EnhancedLogging();
        public static EnhancedLogging Instance => _instance;
        
        private readonly string _logFile = @"C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log";
        private readonly string _logDirectory = @"C:\ProgramData\EmployeeActivityMonitor\logs";
        private readonly int _maxLogSize = 10 * 1024 * 1024; // 10MB
        
        private EnhancedLogging()
        {
            InitializeLogging();
        }
        
        // MARK: - Initialization
        
        private void InitializeLogging()
        {
            try
            {
                if (!Directory.Exists(_logDirectory))
                {
                    Directory.CreateDirectory(_logDirectory);
                }
                
                // Create log file if it doesn't exist
                if (!File.Exists(_logFile))
                {
                    File.Create(_logFile).Close();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to initialize logging: {ex.Message}");
            }
        }
        
        // MARK: - Main Logging Methods
        
        public async Task LogEventAsync(ActivityEvent activityEvent, DeviceInfo deviceInfo = null, Dictionary<string, object> additionalDetails = null)
        {
            var logEntry = CreateDetailedLogEntry(activityEvent, deviceInfo, additionalDetails);
            
            await Task.Run(() => WriteLogEntry(logEntry));
            
            // Print enhanced log to console
            PrintEnhancedLog(logEntry);
            
            // Also print simple event message
            Console.WriteLine($"📝 LOGGED EVENT: {activityEvent.Description}");
        }
        
        public async Task LogUsbEventAsync(UsbDeviceInfo deviceInfo, bool blocked, string reason)
        {
            var activityEvent = new ActivityEvent
            {
                Type = blocked ? ActivityType.UsbBlocked : ActivityType.UsbDrive,
                Description = blocked ? $"USB device blocked: {deviceInfo.DeviceName ?? deviceInfo.DeviceId}" : $"USB device connected: {deviceInfo.DeviceName ?? deviceInfo.DeviceId}",
                Severity = blocked ? ActivitySeverity.High : ActivitySeverity.Medium,
                Details = new Dictionary<string, string>
                {
                    ["DeviceID"] = deviceInfo.DeviceId,
                    ["DeviceName"] = deviceInfo.DeviceName ?? "Unknown",
                    ["VendorID"] = deviceInfo.VendorId ?? "Unknown",
                    ["ProductID"] = deviceInfo.ProductId ?? "Unknown",
                    ["SerialNumber"] = deviceInfo.SerialNumber ?? "Unknown",
                    ["Blocked"] = blocked.ToString(),
                    ["Reason"] = reason
                }
            };
            
            var deviceInfoObj = DeviceInfoManager.GetDeviceInfo();
            var additionalDetails = new Dictionary<string, object>
            {
                ["usbDeviceDetails"] = new Dictionary<string, object>
                {
                    ["deviceId"] = deviceInfo.DeviceId,
                    ["deviceName"] = deviceInfo.DeviceName ?? "Unknown",
                    ["vendorId"] = deviceInfo.VendorId ?? "Unknown",
                    ["productId"] = deviceInfo.ProductId ?? "Unknown",
                    ["serialNumber"] = deviceInfo.SerialNumber ?? "Unknown",
                    ["blocked"] = blocked,
                    ["reason"] = reason
                }
            };
            
            await LogEventAsync(activityEvent, deviceInfoObj, additionalDetails);
        }
        
        public async Task LogFileTransferAsync(string filePath, string eventType, string directory, long? fileSize = null)
        {
            var fileName = Path.GetFileName(filePath);
            var activityEvent = new ActivityEvent
            {
                Type = ActivityType.FileTransfer,
                Description = $"File {eventType.ToLower()}: {fileName}",
                Severity = ActivitySeverity.Medium,
                Details = new Dictionary<string, string>
                {
                    ["FilePath"] = filePath,
                    ["FileName"] = fileName,
                    ["EventType"] = eventType,
                    ["Directory"] = directory,
                    ["FileSize"] = fileSize?.ToString() ?? "Unknown"
                }
            };
            
            var deviceInfo = DeviceInfoManager.GetDeviceInfo();
            var additionalDetails = new Dictionary<string, object>
            {
                ["fileTransferDetails"] = new Dictionary<string, object>
                {
                    ["fileName"] = fileName,
                    ["filePath"] = filePath,
                    ["eventType"] = eventType,
                    ["directory"] = directory,
                    ["fileSize"] = fileSize?.ToString() ?? "Unknown"
                }
            };
            
            await LogEventAsync(activityEvent, deviceInfo, additionalDetails);
        }
        
        public async Task LogAppInstallationAsync(string appName, string publisher, string installPath)
        {
            var activityEvent = new ActivityEvent
            {
                Type = ActivityType.AppInstallation,
                Description = $"App installation: {appName}",
                Severity = ActivitySeverity.Medium,
                Details = new Dictionary<string, string>
                {
                    ["AppName"] = appName,
                    ["Publisher"] = publisher,
                    ["InstallPath"] = installPath
                }
            };
            
            var deviceInfo = DeviceInfoManager.GetDeviceInfo();
            var additionalDetails = new Dictionary<string, object>
            {
                ["appInstallationDetails"] = new Dictionary<string, object>
                {
                    ["appName"] = appName,
                    ["publisher"] = publisher,
                    ["installPath"] = installPath
                }
            };
            
            await LogEventAsync(activityEvent, deviceInfo, additionalDetails);
        }
        
        public async Task LogBlacklistedAppAsync(string appName, string publisher, string installPath)
        {
            var activityEvent = new ActivityEvent
            {
                Type = ActivityType.BlacklistedApp,
                Description = $"Blacklisted app detected: {appName}",
                Severity = ActivitySeverity.High,
                Details = new Dictionary<string, string>
                {
                    ["AppName"] = appName,
                    ["Publisher"] = publisher,
                    ["InstallPath"] = installPath,
                    ["Blacklisted"] = "true"
                }
            };
            
            var deviceInfo = DeviceInfoManager.GetDeviceInfo();
            var additionalDetails = new Dictionary<string, object>
            {
                ["blacklistedAppDetails"] = new Dictionary<string, object>
                {
                    ["appName"] = appName,
                    ["publisher"] = publisher,
                    ["installPath"] = installPath
                }
            };
            
            await LogEventAsync(activityEvent, deviceInfo, additionalDetails);
        }
        
        public async Task LogNetworkActivityAsync(string domain, string connectionType, int? localPort = null, int? remotePort = null)
        {
            var activityEvent = new ActivityEvent
            {
                Type = ActivityType.NetworkActivity,
                Description = $"Suspicious network connection: {domain}",
                Severity = ActivitySeverity.High,
                Details = new Dictionary<string, string>
                {
                    ["Domain"] = domain,
                    ["ConnectionType"] = connectionType,
                    ["LocalPort"] = localPort?.ToString() ?? "Unknown",
                    ["RemotePort"] = remotePort?.ToString() ?? "Unknown"
                }
            };
            
            var deviceInfo = DeviceInfoManager.GetDeviceInfo();
            var additionalDetails = new Dictionary<string, object>
            {
                ["networkActivityDetails"] = new Dictionary<string, object>
                {
                    ["domain"] = domain,
                    ["connectionType"] = connectionType,
                    ["localPort"] = localPort?.ToString() ?? "Unknown",
                    ["remotePort"] = remotePort?.ToString() ?? "Unknown"
                }
            };
            
            await LogEventAsync(activityEvent, deviceInfo, additionalDetails);
        }
        
        public async Task LogUninstallDetectionAsync(int processId, string processName, string commandLine)
        {
            var activityEvent = new ActivityEvent
            {
                Type = ActivityType.UninstallDetected,
                Description = $"Uninstall detected: {processName}",
                Severity = ActivitySeverity.Critical,
                Details = new Dictionary<string, string>
                {
                    ["ProcessID"] = processId.ToString(),
                    ["ProcessName"] = processName,
                    ["CommandLine"] = commandLine
                }
            };
            
            var deviceInfo = DeviceInfoManager.GetDeviceInfo();
            var additionalDetails = new Dictionary<string, object>
            {
                ["uninstallDetails"] = new Dictionary<string, object>
                {
                    ["processId"] = processId,
                    ["processName"] = processName,
                    ["commandLine"] = commandLine,
                    ["uninstallTime"] = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                }
            };
            
            await LogEventAsync(activityEvent, deviceInfo, additionalDetails);
        }
        
        // MARK: - Detailed Log Entry Creation
        
        private Dictionary<string, object> CreateDetailedLogEntry(ActivityEvent activityEvent, DeviceInfo deviceInfo, Dictionary<string, object> additionalDetails)
        {
            var logEntry = new Dictionary<string, object>
            {
                ["timestamp"] = activityEvent.Timestamp.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"),
                ["eventType"] = activityEvent.Type.ToString(),
                ["severity"] = activityEvent.Severity.ToString(),
                ["description"] = activityEvent.Description,
                ["computer"] = activityEvent.Computer,
                ["user"] = activityEvent.User,
                ["details"] = activityEvent.Details
            };
            
            // Add device information
            if (deviceInfo != null)
            {
                logEntry["deviceInfo"] = new Dictionary<string, object>
                {
                    ["serialNumber"] = deviceInfo.SerialNumber,
                    ["primaryMacAddress"] = deviceInfo.PrimaryMacAddress,
                    ["allMacAddresses"] = deviceInfo.MacAddresses,
                    ["biosSerialNumber"] = deviceInfo.BiosSerialNumber,
                    ["motherboardSerialNumber"] = deviceInfo.MotherboardSerialNumber,
                    ["windowsProductId"] = deviceInfo.WindowsProductId,
                    ["installationPath"] = deviceInfo.InstallationPath,
                    ["deviceFingerprint"] = deviceInfo.DeviceFingerprint,
                    ["processorInfo"] = DeviceInfoManager.GetProcessorInfo(),
                    ["memoryInfo"] = DeviceInfoManager.GetMemoryInfo(),
                    ["diskInfo"] = DeviceInfoManager.GetDiskInfo(),
                    ["networkInfo"] = DeviceInfoManager.GetNetworkInfo()
                };
            }
            
            // Add additional details
            if (additionalDetails != null)
            {
                foreach (var kvp in additionalDetails)
                {
                    logEntry[kvp.Key] = kvp.Value;
                }
            }
            
            return logEntry;
        }
        
        // MARK: - Console Output
        
        private void PrintEnhancedLog(Dictionary<string, object> logEntry)
        {
            Console.WriteLine("🔍 ENHANCED LOG ENTRY:");
            Console.WriteLine($"📅 Time: {logEntry.GetValueOrDefault("timestamp", "Unknown")}");
            Console.WriteLine($"🖥️ Computer: {logEntry.GetValueOrDefault("computer", "Unknown")}");
            Console.WriteLine($"👤 User: {logEntry.GetValueOrDefault("user", "Unknown")}");
            
            if (logEntry.ContainsKey("deviceInfo") && logEntry["deviceInfo"] is Dictionary<string, object> deviceInfo)
            {
                Console.WriteLine($"📱 Serial Number: {deviceInfo.GetValueOrDefault("serialNumber", "Unknown")}");
                Console.WriteLine($"🌐 MAC Address: {deviceInfo.GetValueOrDefault("primaryMacAddress", "Unknown")}");
                Console.WriteLine($"🔧 BIOS Serial: {deviceInfo.GetValueOrDefault("biosSerialNumber", "Unknown")}");
                Console.WriteLine($"💻 Windows Product ID: {deviceInfo.GetValueOrDefault("windowsProductId", "Unknown")}");
                Console.WriteLine($"⚡ Processor: {deviceInfo.GetValueOrDefault("processorInfo", "Unknown")}");
                Console.WriteLine($"💾 Memory: {deviceInfo.GetValueOrDefault("memoryInfo", "Unknown")}");
                Console.WriteLine($"💿 Disk: {deviceInfo.GetValueOrDefault("diskInfo", "Unknown")}");
                Console.WriteLine($"🌐 Network: {deviceInfo.GetValueOrDefault("networkInfo", "Unknown")}");
            }
            else
            {
                Console.WriteLine("📱 Serial Number: Unknown");
                Console.WriteLine("🌐 MAC Address: Unknown");
                Console.WriteLine("🔧 BIOS Serial: Unknown");
                Console.WriteLine("💻 Windows Product ID: Unknown");
                Console.WriteLine("⚡ Processor: Unknown");
                Console.WriteLine("💾 Memory: Unknown");
                Console.WriteLine("💿 Disk: Unknown");
                Console.WriteLine("🌐 Network: Unknown");
            }
            
            Console.WriteLine($"🎯 Event: {logEntry.GetValueOrDefault("description", "Unknown")}");
            
            if (logEntry.ContainsKey("details") && logEntry["details"] is Dictionary<string, string> details)
            {
                Console.WriteLine("📋 Details:");
                foreach (var kvp in details)
                {
                    Console.WriteLine($"   {kvp.Key}: {kvp.Value}");
                }
            }
            
            Console.WriteLine("---");
        }
        
        // MARK: - File Operations
        
        private void WriteLogEntry(Dictionary<string, object> logEntry)
        {
            try
            {
                var logJson = System.Text.Json.JsonSerializer.Serialize(logEntry, new System.Text.Json.JsonSerializerOptions { WriteIndented = true });
                var logString = logJson + "\n---\n";
                
                // Check if log file exists and rotate if needed
                if (File.Exists(_logFile))
                {
                    var fileInfo = new FileInfo(_logFile);
                    if (fileInfo.Length > _maxLogSize)
                    {
                        RotateLogFile();
                    }
                }
                
                // Write to log file
                File.AppendAllText(_logFile, logString);
                
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to write log entry: {ex.Message}");
            }
        }
        
        private void RotateLogFile()
        {
            try
            {
                var backupPath = _logFile + ".1";
                
                // Remove old backup if it exists
                if (File.Exists(backupPath))
                {
                    File.Delete(backupPath);
                }
                
                // Move current log to backup
                File.Move(_logFile, backupPath);
                
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to rotate log file: {ex.Message}");
            }
        }
        
        // MARK: - Log Retrieval
        
        public List<Dictionary<string, object>> GetRecentLogs(int limit = 100)
        {
            try
            {
                if (!File.Exists(_logFile))
                    return new List<Dictionary<string, object>>();
                
                var logContent = File.ReadAllText(_logFile);
                var entries = logContent.Split("\n---\n")
                    .Where(entry => !string.IsNullOrWhiteSpace(entry))
                    .TakeLast(limit)
                    .ToList();
                
                var logs = new List<Dictionary<string, object>>();
                foreach (var entry in entries)
                {
                    try
                    {
                        var logEntry = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(entry);
                        if (logEntry != null)
                        {
                            logs.Add(logEntry);
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Failed to parse log entry: {ex.Message}");
                    }
                }
                
                logs.Reverse();
                return logs;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to read log file: {ex.Message}");
                return new List<Dictionary<string, object>>();
            }
        }
        
        public List<Dictionary<string, object>> GetLogsByType(ActivityType eventType, int limit = 50)
        {
            var allLogs = GetRecentLogs(1000);
            return allLogs.Where(log => 
                log.ContainsKey("eventType") && 
                log["eventType"]?.ToString() == eventType.ToString()
            ).Take(limit).ToList();
        }
        
        public List<Dictionary<string, object>> GetLogsBySeverity(ActivitySeverity severity, int limit = 50)
        {
            var allLogs = GetRecentLogs(1000);
            return allLogs.Where(log => 
                log.ContainsKey("severity") && 
                log["severity"]?.ToString() == severity.ToString()
            ).Take(limit).ToList();
        }
        
        // MARK: - Statistics
        
        public Dictionary<string, object> GetLogStatistics()
        {
            var allLogs = GetRecentLogs(10000);
            
            var statistics = new Dictionary<string, object>
            {
                ["totalEvents"] = allLogs.Count,
                ["eventsByType"] = new Dictionary<string, int>(),
                ["eventsBySeverity"] = new Dictionary<string, int>(),
                ["recentActivity"] = allLogs.Take(10).ToList()
            };
            
            // Count by type
            var typeCounts = new Dictionary<string, int>();
            var severityCounts = new Dictionary<string, int>();
            
            foreach (var log in allLogs)
            {
                if (log.ContainsKey("eventType"))
                {
                    var type = log["eventType"]?.ToString() ?? "Unknown";
                    typeCounts[type] = typeCounts.GetValueOrDefault(type, 0) + 1;
                }
                
                if (log.ContainsKey("severity"))
                {
                    var severity = log["severity"]?.ToString() ?? "Unknown";
                    severityCounts[severity] = severityCounts.GetValueOrDefault(severity, 0) + 1;
                }
            }
            
            statistics["eventsByType"] = typeCounts;
            statistics["eventsBySeverity"] = severityCounts;
            
            return statistics;
        }
        
        // MARK: - Log Cleanup
        
        public void CleanupOldLogs(int daysToKeep = 30)
        {
            try
            {
                var cutoffDate = DateTime.Now.AddDays(-daysToKeep);
                var logFiles = Directory.GetFiles(_logDirectory, "*.log*");
                
                foreach (var file in logFiles)
                {
                    var fileInfo = new FileInfo(file);
                    if (fileInfo.CreationTime < cutoffDate)
                    {
                        File.Delete(file);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to cleanup old logs: {ex.Message}");
            }
        }
    }
    
    // MARK: - Logging Extensions
    
    public static class LoggingExtensions
    {
        public static async Task LogWithDetailsAsync(this ActivityEvent activityEvent, DeviceInfo deviceInfo = null, Dictionary<string, object> additionalDetails = null)
        {
            await EnhancedLogging.Instance.LogEventAsync(activityEvent, deviceInfo, additionalDetails);
        }
        
        public static async Task LogConnectionAsync(this UsbDeviceInfo deviceInfo, bool blocked, string reason)
        {
            await EnhancedLogging.Instance.LogUsbEventAsync(deviceInfo, blocked, reason);
        }
    }
} 