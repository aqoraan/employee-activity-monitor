using System;
using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;

namespace SystemMonitor
{
    public class AppConfig
    {
        public string N8nWebhookUrl { get; set; } = "http://localhost:5678/webhook/monitoring";
        public List<string> BlacklistedApps { get; set; } = new List<string>();
        public List<string> SuspiciousDomains { get; set; } = new List<string>();
        public MonitoringSettings MonitoringSettings { get; set; } = new MonitoringSettings();
        public EmailSettings EmailSettings { get; set; } = new EmailSettings();

        public static AppConfig LoadFromFile(string filePath = "config.json")
        {
            try
            {
                if (File.Exists(filePath))
                {
                    var json = File.ReadAllText(filePath);
                    var config = JsonConvert.DeserializeObject<AppConfig>(json);
                    
                    // Set defaults if not specified
                    if (config.BlacklistedApps.Count == 0)
                    {
                        config.BlacklistedApps = GetDefaultBlacklistedApps();
                    }
                    
                    if (config.SuspiciousDomains.Count == 0)
                    {
                        config.SuspiciousDomains = GetDefaultSuspiciousDomains();
                    }
                    
                    return config;
                }
            }
            catch (Exception ex)
            {
                // Log error but continue with defaults
                Console.WriteLine($"Failed to load config file: {ex.Message}");
            }

            // Return default configuration
            return new AppConfig
            {
                BlacklistedApps = GetDefaultBlacklistedApps(),
                SuspiciousDomains = GetDefaultSuspiciousDomains(),
                MonitoringSettings = new MonitoringSettings(),
                EmailSettings = new EmailSettings()
            };
        }

        public void SaveToFile(string filePath = "config.json")
        {
            try
            {
                var json = JsonConvert.SerializeObject(this, Formatting.Indented);
                File.WriteAllText(filePath, json);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to save config file: {ex.Message}");
            }
        }

        private static List<string> GetDefaultBlacklistedApps()
        {
            return new List<string>
            {
                "tor.exe", "vpn.exe", "proxy.exe", "anonymizer.exe",
                "cryptolocker.exe", "ransomware.exe", "keylogger.exe",
                "spyware.exe", "malware.exe", "trojan.exe",
                "hacktool.exe", "crack.exe", "keygen.exe", "patch.exe"
            };
        }

        private static List<string> GetDefaultSuspiciousDomains()
        {
            return new List<string>
            {
                "mega.nz", "dropbox.com", "google-drive.com", "onedrive.com",
                "we-transfer.com", "file.io", "transfernow.net", "wetransfer.com",
                "sendspace.com", "rapidshare.com", "mediafire.com", "4shared.com"
            };
        }
    }

    public class MonitoringSettings
    {
        public bool EnableUsbMonitoring { get; set; } = true;
        public bool EnableFileTransferMonitoring { get; set; } = true;
        public bool EnableAppInstallationMonitoring { get; set; } = true;
        public bool EnableNetworkMonitoring { get; set; } = true;
        public bool EnableBlacklistedAppMonitoring { get; set; } = true;
        public string LogLevel { get; set; } = "Medium";
        public int MaxLogEntries { get; set; } = 10000;
        public bool AutoStartMonitoring { get; set; } = false;
        public bool SendToN8n { get; set; } = true;
        public int N8nRetryAttempts { get; set; } = 3;
        public int N8nRetryDelayMs { get; set; } = 5000;
    }

    public class EmailSettings
    {
        public string SmtpServer { get; set; } = "smtp.gmail.com";
        public int SmtpPort { get; set; } = 587;
        public bool UseSsl { get; set; } = true;
        public string Username { get; set; } = "";
        public string Password { get; set; } = "";
        public string FromEmail { get; set; } = "security@yourcompany.com";
        public string ToEmail { get; set; } = "admin@yourcompany.com";
        public string CcEmail { get; set; } = "";
        public bool EnableEmailAlerts { get; set; } = false;
    }
} 