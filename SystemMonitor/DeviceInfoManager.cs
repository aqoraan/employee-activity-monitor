using System;
using System.Management;
using System.Net.NetworkInformation;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Win32;

namespace SystemMonitor
{
    public class DeviceInfoManager
    {
        public static DeviceInfo GetDeviceInfo()
        {
            var deviceInfo = new DeviceInfo
            {
                ComputerName = Environment.MachineName,
                UserName = Environment.UserName,
                Timestamp = DateTime.Now,
                SerialNumber = GetSystemSerialNumber(),
                MacAddresses = GetMacAddresses(),
                BiosSerialNumber = GetBiosSerialNumber(),
                MotherboardSerialNumber = GetMotherboardSerialNumber(),
                WindowsProductId = GetWindowsProductId(),
                InstallationPath = GetInstallationPath()
            };

            return deviceInfo;
        }

        private static string GetSystemSerialNumber()
        {
            try
            {
                using (var searcher = new ManagementObjectSearcher("SELECT * FROM Win32_ComputerSystem"))
                {
                    foreach (ManagementObject obj in searcher.Get())
                    {
                        return obj["SerialNumber"]?.ToString() ?? "Unknown";
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to get system serial number: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Warning);
            }
            return "Unknown";
        }

        private static List<string> GetMacAddresses()
        {
            var macAddresses = new List<string>();
            try
            {
                using (var searcher = new ManagementObjectSearcher("SELECT * FROM Win32_NetworkAdapter WHERE PhysicalAdapter = True"))
                {
                    foreach (ManagementObject obj in searcher.Get())
                    {
                        var macAddress = obj["MACAddress"]?.ToString();
                        if (!string.IsNullOrEmpty(macAddress))
                        {
                            macAddresses.Add(macAddress);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to get MAC addresses: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Warning);
            }
            return macAddresses;
        }

        private static string GetBiosSerialNumber()
        {
            try
            {
                using (var searcher = new ManagementObjectSearcher("SELECT * FROM Win32_BIOS"))
                {
                    foreach (ManagementObject obj in searcher.Get())
                    {
                        return obj["SerialNumber"]?.ToString() ?? "Unknown";
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to get BIOS serial number: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Warning);
            }
            return "Unknown";
        }

        private static string GetMotherboardSerialNumber()
        {
            try
            {
                using (var searcher = new ManagementObjectSearcher("SELECT * FROM Win32_BaseBoard"))
                {
                    foreach (ManagementObject obj in searcher.Get())
                    {
                        return obj["SerialNumber"]?.ToString() ?? "Unknown";
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to get motherboard serial number: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Warning);
            }
            return "Unknown";
        }

        private static string GetWindowsProductId()
        {
            try
            {
                using (var key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion"))
                {
                    if (key != null)
                    {
                        return key.GetValue("ProductId")?.ToString() ?? "Unknown";
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to get Windows Product ID: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Warning);
            }
            return "Unknown";
        }

        private static string GetInstallationPath()
        {
            try
            {
                return System.Reflection.Assembly.GetExecutingAssembly().Location;
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to get installation path: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Warning);
            }
            return "Unknown";
        }

        public static string GetPrimaryMacAddress()
        {
            var macAddresses = GetMacAddresses();
            return macAddresses.FirstOrDefault() ?? "Unknown";
        }

        public static string GetDeviceFingerprint()
        {
            var deviceInfo = GetDeviceInfo();
            return $"{deviceInfo.ComputerName}_{deviceInfo.SerialNumber}_{deviceInfo.PrimaryMacAddress}";
        }
    }

    public class DeviceInfo
    {
        public string ComputerName { get; set; }
        public string UserName { get; set; }
        public DateTime Timestamp { get; set; }
        public string SerialNumber { get; set; }
        public List<string> MacAddresses { get; set; } = new List<string>();
        public string BiosSerialNumber { get; set; }
        public string MotherboardSerialNumber { get; set; }
        public string WindowsProductId { get; set; }
        public string InstallationPath { get; set; }
        public string PrimaryMacAddress => MacAddresses.FirstOrDefault() ?? "Unknown";
    }
} 