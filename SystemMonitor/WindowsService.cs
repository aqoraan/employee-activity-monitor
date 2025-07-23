using System;
using System.Configuration.Install;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.ServiceProcess;
using System.Threading;
using System.Threading.Tasks;

namespace SystemMonitor
{
    public class WindowsService : ServiceBase
    {
        private MonitoringService _monitoringService;
        private AppConfig _config;
        private bool _isRunning = false;

        public WindowsService()
        {
            ServiceName = "EmployeeActivityMonitor";
            CanStop = false;
            CanPauseAndContinue = false;
            AutoLog = true;
        }

        protected override void OnStart(string[] args)
        {
            try
            {
                _config = AppConfig.LoadFromFile();
                _monitoringService = new MonitoringService(_config);
                _monitoringService.ActivityDetected += OnActivityDetected;
                
                _monitoringService.StartMonitoring();
                _isRunning = true;
                
                // Log service start
                EventLog.WriteEntry($"Employee Activity Monitor service started successfully on {Environment.MachineName}", EventLogEntryType.Information);
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry($"Failed to start Employee Activity Monitor service: {ex.Message}", EventLogEntryType.Error);
                throw;
            }
        }

        protected override void OnStop()
        {
            try
            {
                _isRunning = false;
                _monitoringService?.StopMonitoring();
                _monitoringService?.Dispose();
                
                EventLog.WriteEntry("Employee Activity Monitor service stopped", EventLogEntryType.Information);
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry($"Error stopping Employee Activity Monitor service: {ex.Message}", EventLogEntryType.Error);
            }
        }

        private void OnActivityDetected(object sender, ActivityEventArgs e)
        {
            // Log to Windows Event Log
            EventLog.WriteEntry($"Activity detected: {e.Description}", EventLogEntryType.Information);
            
            // Send to N8N asynchronously
            _ = Task.Run(async () =>
            {
                try
                {
                    await _monitoringService.SendToN8n(e);
                }
                catch (Exception ex)
                {
                    EventLog.WriteEntry($"Failed to send to N8N: {ex.Message}", EventLogEntryType.Warning);
                }
            });
        }

        public static void InstallService()
        {
            try
            {
                var path = Assembly.GetExecutingAssembly().Location;
                var installer = new AssemblyInstaller(path, null);
                installer.UseNewContext = true;
                installer.Install(null);
                installer.Commit(null);
                
                // Set service to auto-start
                var sc = new ServiceController("EmployeeActivityMonitor");
                var config = new ServiceControllerPermission(ServiceControllerPermissionAccess.Control, "EmployeeActivityMonitor");
                config.Demand();
                
                // Configure service to auto-start
                var process = new Process();
                process.StartInfo.FileName = "sc";
                process.StartInfo.Arguments = "config EmployeeActivityMonitor start= auto";
                process.StartInfo.UseShellExecute = false;
                process.StartInfo.CreateNoWindow = true;
                process.Start();
                process.WaitForExit();
                
                // Start the service
                sc.Start();
                sc.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromSeconds(30));
            }
            catch (Exception ex)
            {
                throw new Exception($"Failed to install service: {ex.Message}");
            }
        }

        public static void UninstallService()
        {
            try
            {
                var path = Assembly.GetExecutingAssembly().Location;
                var installer = new AssemblyInstaller(path, null);
                installer.UseNewContext = true;
                installer.Uninstall(null);
            }
            catch (Exception ex)
            {
                throw new Exception($"Failed to uninstall service: {ex.Message}");
            }
        }
    }

    [RunInstaller(true)]
    public class ProjectInstaller : Installer
    {
        private ServiceProcessInstaller _processInstaller;
        private ServiceInstaller _serviceInstaller;

        public ProjectInstaller()
        {
            _processInstaller = new ServiceProcessInstaller();
            _serviceInstaller = new ServiceInstaller();

            _processInstaller.Account = ServiceAccount.LocalSystem;
            _processInstaller.Username = null;
            _processInstaller.Password = null;

            _serviceInstaller.ServiceName = "EmployeeActivityMonitor";
            _serviceInstaller.DisplayName = "Employee Activity Monitor";
            _serviceInstaller.Description = "Monitors employee activities including USB drives, file transfers, and application installations";
            _serviceInstaller.StartType = ServiceStartMode.Automatic;

            Installers.AddRange(new Installer[] { _processInstaller, _serviceInstaller });
        }
    }
} 