using System;
using System.ServiceProcess;
using System.Windows;

namespace SystemMonitor
{
    public class Program
    {
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
    }
} 