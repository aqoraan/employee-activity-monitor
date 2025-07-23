using System;
using System.ServiceProcess;
using System.Windows;
using System.Threading.Tasks;

namespace SystemMonitor
{
    public class Program
    {
        private static MonitoringService _monitoringService;

        [STAThread]
        public static void Main(string[] args)
        {
            try
            {
                // Check for service installation/management commands
                if (args.Length > 0)
                {
                    switch (args[0].ToLower())
                    {
                        case "--install":
                            if (!SecurityManager.IsRunningAsAdministrator())
                            {
                                Console.WriteLine("Error: Administrative privileges required to install service.");
                                return;
                            }
                            
                            SecurityManager.InstallAsService();
                            SecurityManager.ProtectConfiguration();
                            SecurityManager.PreventUninstallation();
                            SecurityManager.SetRegistryProtection();
                            Console.WriteLine("Service installed successfully.");
                            return;

                        case "--uninstall":
                            if (!SecurityManager.IsRunningAsAdministrator())
                            {
                                Console.WriteLine("Error: Administrative privileges required to uninstall service.");
                                return;
                            }
                            
                            // Send uninstall notification before removing service
                            SendUninstallNotificationAsync().Wait();
                            
                            WindowsService.UninstallService();
                            Console.WriteLine("Service uninstalled successfully.");
                            return;

                        case "--service":
                            // Run as Windows Service
                            ServiceBase.Run(new WindowsService());
                            return;

                        case "--validate-admin":
                            var email = args.Length > 1 ? args[1] : "";
                            var token = args.Length > 2 ? args[2] : "";
                            
                            if (SecurityManager.ValidateAdminAccess(email, token))
                            {
                                Console.WriteLine("Admin access validated successfully.");
                                return;
                            }
                            else
                            {
                                Console.WriteLine("Error: Admin access denied.");
                                return;
                            }

                        case "--uninstall-notification":
                            // Send uninstall notification only
                            SendUninstallNotificationAsync().Wait();
                            return;
                    }
                }

                // Check if running as administrator
                if (!SecurityManager.IsRunningAsAdministrator())
                {
                    MessageBox.Show("This application requires administrative privileges to monitor system activities.", 
                        "Administrative Rights Required", MessageBoxButton.OK, MessageBoxImage.Warning);
                    
                    // Try to restart with elevated privileges
                    try
                    {
                        var process = new System.Diagnostics.Process();
                        process.StartInfo.FileName = System.Reflection.Assembly.GetExecutingAssembly().Location;
                        process.StartInfo.UseShellExecute = true;
                        process.StartInfo.Verb = "runas";
                        process.Start();
                    }
                    catch
                    {
                        // If elevation fails, exit
                        Environment.Exit(1);
                    }
                    return;
                }

                // Log security event
                SecurityManager.LogSecurityEvent("Application started", Environment.UserName);

                // Check if service is installed and running
                if (SecurityManager.IsServiceInstalled())
                {
                    using (var service = new ServiceController("EmployeeActivityMonitor"))
                    {
                        if (service.Status == ServiceControllerStatus.Running)
                        {
                            MessageBox.Show("Employee Activity Monitor is already running as a Windows Service.", 
                                "Service Running", MessageBoxButton.OK, MessageBoxImage.Information);
                            return;
                        }
                    }
                }

                // Initialize monitoring service for uninstall detection
                var config = AppConfig.LoadFromFile();
                _monitoringService = new MonitoringService(config);

                // Set up application exit handler
                AppDomain.CurrentDomain.ProcessExit += OnProcessExit;
                Console.CancelKeyPress += OnCancelKeyPress;

                // Run as WPF application
                var app = new App();
                app.InitializeComponent();
                app.Run();
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Application error: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Error);
                
                MessageBox.Show($"Application error: {ex.Message}", "Error", 
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private static async void OnProcessExit(object sender, EventArgs e)
        {
            try
            {
                // Send uninstall notification if this is an uninstall scenario
                if (IsUninstallScenario())
                {
                    await SendUninstallNotificationAsync();
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Error in process exit handler: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Error);
            }
        }

        private static void OnCancelKeyPress(object sender, ConsoleCancelEventArgs e)
        {
            try
            {
                // Send uninstall notification if this is an uninstall scenario
                if (IsUninstallScenario())
                {
                    SendUninstallNotificationAsync().Wait();
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Error in cancel key press handler: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Error);
            }
        }

        private static bool IsUninstallScenario()
        {
            try
            {
                // Check if this is an uninstall scenario by looking for uninstall flags
                var uninstallFlagFile = System.IO.Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), 
                    "EmployeeActivityMonitor", "uninstall_detected.flag");

                if (System.IO.File.Exists(uninstallFlagFile))
                {
                    return true;
                }

                // Check command line arguments for uninstall indicators
                var commandLine = Environment.CommandLine.ToLower();
                if (commandLine.Contains("uninstall") || commandLine.Contains("remove"))
                {
                    return true;
                }

                // Check if running from uninstaller process
                var processName = System.Diagnostics.Process.GetCurrentProcess().ProcessName.ToLower();
                if (processName.Contains("uninstall") || processName.Contains("remove"))
                {
                    return true;
                }

                return false;
            }
            catch
            {
                return false;
            }
        }

        private static async Task SendUninstallNotificationAsync()
        {
            try
            {
                if (_monitoringService != null)
                {
                    await _monitoringService.SendUninstallNotification();
                }
                else
                {
                    // Create temporary monitoring service to send notification
                    var config = AppConfig.LoadFromFile();
                    using (var tempService = new MonitoringService(config))
                    {
                        await tempService.SendUninstallNotification();
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to send uninstall notification: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Error);
            }
        }
    }
} 