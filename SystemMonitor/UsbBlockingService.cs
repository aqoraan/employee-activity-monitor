using System;
using System.Management;
using System.Threading.Tasks;
using System.Diagnostics;
using System.Collections.Generic;
using System.Linq;

namespace SystemMonitor
{
    public class UsbBlockingService
    {
        private readonly GoogleSheetsManager _sheetsManager;
        private readonly bool _enableBlocking;
        private readonly List<string> _blockedDevices;
        private ManagementEventWatcher _deviceWatcher;

        public event EventHandler<UsbBlockingEventArgs> UsbBlocked;

        public UsbBlockingService(GoogleSheetsManager sheetsManager, bool enableBlocking = true)
        {
            _sheetsManager = sheetsManager;
            _enableBlocking = enableBlocking;
            _blockedDevices = new List<string>();
        }

        public void StartBlocking()
        {
            if (!_enableBlocking) return;

            try
            {
                // Monitor for USB device insertion
                var query = new WqlEventQuery("SELECT * FROM Win32_DeviceChangeEvent WHERE EventType = 2");
                _deviceWatcher = new ManagementEventWatcher(query);
                _deviceWatcher.EventArrived += OnDeviceInserted;
                _deviceWatcher.Start();

                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    "USB blocking service started", 
                    System.Diagnostics.EventLogEntryType.Information);
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to start USB blocking: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Error);
            }
        }

        public void StopBlocking()
        {
            _deviceWatcher?.Stop();
            _deviceWatcher?.Dispose();
        }

        private async void OnDeviceInserted(object sender, EventArrivedEventArgs e)
        {
            try
            {
                // Get USB device information
                var deviceId = e.NewEvent["DeviceID"]?.ToString();
                if (string.IsNullOrEmpty(deviceId)) return;

                // Check if it's a USB storage device
                if (IsUsbStorageDevice(deviceId))
                {
                    // Check whitelist
                    var isWhitelisted = await _sheetsManager.IsUsbWhitelisted(deviceId);
                    
                    if (!isWhitelisted)
                    {
                        // Block the device
                        await BlockUsbDevice(deviceId);
                        
                        var blockingEvent = new UsbBlockingEventArgs
                        {
                            DeviceId = deviceId,
                            Timestamp = DateTime.Now,
                            Reason = "Device not in whitelist",
                            Blocked = true
                        };

                        UsbBlocked?.Invoke(this, blockingEvent);
                        
                        System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                            $"USB device blocked: {deviceId}", 
                            System.Diagnostics.EventLogEntryType.Warning);
                    }
                    else
                    {
                        System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                            $"USB device allowed: {deviceId}", 
                            System.Diagnostics.EventLogEntryType.Information);
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Error processing USB device: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Error);
            }
        }

        private bool IsUsbStorageDevice(string deviceId)
        {
            try
            {
                // Check if it's a USB storage device
                using (var searcher = new ManagementObjectSearcher(
                    "SELECT * FROM Win32_USBHub WHERE DeviceID = '" + deviceId + "'"))
                {
                    var devices = searcher.Get();
                    return devices.Count > 0;
                }
            }
            catch
            {
                // If we can't determine, assume it's a storage device
                return deviceId.Contains("USB") || deviceId.Contains("STORAGE");
            }
        }

        private async Task BlockUsbDevice(string deviceId)
        {
            try
            {
                // Method 1: Disable the device using WMI
                using (var searcher = new ManagementObjectSearcher(
                    "SELECT * FROM Win32_PnPEntity WHERE DeviceID = '" + deviceId + "'"))
                {
                    var devices = searcher.Get();
                    foreach (ManagementObject device in devices)
                    {
                        try
                        {
                            // Disable the device
                            device.InvokeMethod("Disable", null);
                            _blockedDevices.Add(deviceId);
                        }
                        catch (Exception ex)
                        {
                            System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                                $"Failed to disable device {deviceId}: {ex.Message}", 
                                System.Diagnostics.EventLogEntryType.Warning);
                        }
                    }
                }

                // Method 2: Use PowerShell to disable USB storage
                var process = new Process();
                process.StartInfo.FileName = "powershell.exe";
                process.StartInfo.Arguments = $"-Command \"Get-PnpDevice | Where-Object {{$_.InstanceId -like '*{deviceId}*'}} | Disable-PnpDevice -Confirm:$false\"";
                process.StartInfo.UseShellExecute = false;
                process.StartInfo.CreateNoWindow = true;
                process.Start();
                await process.WaitForExitAsync();

                // Method 3: Registry-based blocking (additional protection)
                BlockUsbInRegistry(deviceId);
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to block USB device {deviceId}: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Error);
            }
        }

        private void BlockUsbInRegistry(string deviceId)
        {
            try
            {
                // Add device to blocked list in registry
                using (var key = Microsoft.Win32.Registry.LocalMachine.CreateSubKey(
                    @"SOFTWARE\EmployeeActivityMonitor\BlockedDevices"))
                {
                    if (key != null)
                    {
                        key.SetValue(deviceId, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to add device to registry block list: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Warning);
            }
        }

        public List<string> GetBlockedDevices()
        {
            return new List<string>(_blockedDevices);
        }

        public void Dispose()
        {
            StopBlocking();
            _sheetsManager?.Dispose();
        }
    }

    public class UsbBlockingEventArgs : EventArgs
    {
        public string DeviceId { get; set; }
        public DateTime Timestamp { get; set; }
        public string Reason { get; set; }
        public bool Blocked { get; set; }
    }
} 