using System;
using System.IO;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;
using Microsoft.Win32;

namespace SystemMonitor
{
    public partial class MainWindow : Window
    {
        private MonitoringService _monitoringService;
        private AppConfig _config;
        private bool _isMonitoring = false;

        public MainWindow()
        {
            InitializeComponent();
            InitializeMonitoringService();
        }

        private void InitializeMonitoringService()
        {
            // Load configuration
            _config = AppConfig.LoadFromFile();
            
            // Initialize monitoring service with configuration
            _monitoringService = new MonitoringService(_config);
            _monitoringService.ActivityDetected += OnActivityDetected;
            
            // Auto-start monitoring if configured
            if (_config.MonitoringSettings.AutoStartMonitoring)
            {
                StartMonitoring_Click(null, null);
            }
        }

        private async void StartMonitoring_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                _monitoringService.StartMonitoring();
                _isMonitoring = true;

                // Update UI
                StartMonitoringBtn.IsEnabled = false;
                StopMonitoringBtn.IsEnabled = true;
                UpdateStatusIndicators(true);
                StatusText.Text = "Monitoring active...";

                LogActivity("Monitoring started successfully");
                
                // Log configuration
                LogActivity($"Configuration loaded - N8N URL: {_config.N8nWebhookUrl}");
                LogActivity($"Blacklisted apps: {_config.BlacklistedApps.Count}");
                LogActivity($"Suspicious domains: {_config.SuspiciousDomains.Count}");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to start monitoring: {ex.Message}", "Error", 
                    MessageBoxButton.OK, MessageBoxImage.Error);
                LogActivity($"Error starting monitoring: {ex.Message}");
            }
        }

        private void StopMonitoring_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                _monitoringService.StopMonitoring();
                _isMonitoring = false;

                // Update UI
                StartMonitoringBtn.IsEnabled = true;
                StopMonitoringBtn.IsEnabled = false;
                UpdateStatusIndicators(false);
                StatusText.Text = "Monitoring stopped";

                LogActivity("Monitoring stopped");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to stop monitoring: {ex.Message}", "Error", 
                    MessageBoxButton.OK, MessageBoxImage.Error);
                LogActivity($"Error stopping monitoring: {ex.Message}");
            }
        }

        private async void TestN8n_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                StatusText.Text = "Testing N8N connection...";
                
                var testActivity = new ActivityEventArgs
                {
                    Type = ActivityType.System,
                    Description = "Test activity from System Monitor",
                    Timestamp = DateTime.Now,
                    Severity = ActivitySeverity.Low,
                    Details = new System.Collections.Generic.Dictionary<string, string>
                    {
                        ["TestMode"] = "true",
                        ["ConfigVersion"] = "1.0"
                    }
                };

                await _monitoringService.SendToN8n(testActivity);
                
                StatusText.Text = "N8N connection test successful";
                LogActivity("N8N connection test successful");
                MessageBox.Show("N8N connection test successful!", "Success", 
                    MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                StatusText.Text = "N8N connection test failed";
                LogActivity($"N8N connection test failed: {ex.Message}");
                MessageBox.Show($"N8N connection test failed: {ex.Message}", "Error", 
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void ClearLog_Click(object sender, RoutedEventArgs e)
        {
            ActivityLog.Clear();
            LogActivity("Activity log cleared");
        }

        private void ExportLog_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                var saveFileDialog = new SaveFileDialog
                {
                    Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*",
                    FileName = $"activity_log_{DateTime.Now:yyyyMMdd_HHmmss}.txt"
                };

                if (saveFileDialog.ShowDialog() == true)
                {
                    File.WriteAllText(saveFileDialog.FileName, ActivityLog.Text);
                    LogActivity($"Activity log exported to: {saveFileDialog.FileName}");
                    MessageBox.Show("Activity log exported successfully!", "Success", 
                        MessageBoxButton.OK, MessageBoxImage.Information);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to export log: {ex.Message}", "Error", 
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void OnActivityDetected(object sender, ActivityEventArgs e)
        {
            // Ensure UI updates happen on the UI thread
            Dispatcher.Invoke(() =>
            {
                LogActivity($"[{e.Timestamp:HH:mm:ss}] {e.Description}");
                
                // Send to N8N asynchronously if enabled
                if (_config.MonitoringSettings.SendToN8n)
                {
                    _ = Task.Run(async () =>
                    {
                        try
                        {
                            await _monitoringService.SendToN8n(e);
                        }
                        catch (Exception ex)
                        {
                            Dispatcher.Invoke(() => LogActivity($"Failed to send to N8N: {ex.Message}"));
                        }
                    });
                }

                // Update status based on activity type
                UpdateStatusForActivity(e);
            });
        }

        private void LogActivity(string message)
        {
            var timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            var logEntry = $"[{timestamp}] {message}{Environment.NewLine}";
            
            ActivityLog.AppendText(logEntry);
            ActivityLog.ScrollToEnd();
            
            // Limit log entries if configured
            if (_config.MonitoringSettings.MaxLogEntries > 0)
            {
                var lines = ActivityLog.Text.Split(Environment.NewLine);
                if (lines.Length > _config.MonitoringSettings.MaxLogEntries)
                {
                    var trimmedLines = lines.Skip(lines.Length - _config.MonitoringSettings.MaxLogEntries);
                    ActivityLog.Text = string.Join(Environment.NewLine, trimmedLines);
                }
            }
        }

        private void UpdateStatusIndicators(bool isActive)
        {
            var color = isActive ? Brushes.Green : Brushes.Red;
            
            UsbStatus.Fill = color;
            FileTransferStatus.Fill = color;
            AppInstallStatus.Fill = color;
            NetworkStatus.Fill = color;
        }

        private void UpdateStatusForActivity(ActivityEventArgs activity)
        {
            var color = activity.Severity switch
            {
                ActivitySeverity.Low => Brushes.Orange,
                ActivitySeverity.Medium => Brushes.Yellow,
                ActivitySeverity.High => Brushes.Red,
                ActivitySeverity.Critical => Brushes.DarkRed,
                _ => Brushes.Gray
            };

            switch (activity.Type)
            {
                case ActivityType.UsbDrive:
                    UsbStatus.Fill = color;
                    break;
                case ActivityType.FileTransfer:
                    FileTransferStatus.Fill = color;
                    break;
                case ActivityType.AppInstallation:
                case ActivityType.BlacklistedApp:
                    AppInstallStatus.Fill = color;
                    break;
                case ActivityType.NetworkActivity:
                    NetworkStatus.Fill = color;
                    break;
            }

            // Reset status after a delay
            Task.Delay(5000).ContinueWith(_ =>
            {
                Dispatcher.Invoke(() =>
                {
                    if (_isMonitoring)
                    {
                        UsbStatus.Fill = Brushes.Green;
                        FileTransferStatus.Fill = Brushes.Green;
                        AppInstallStatus.Fill = Brushes.Green;
                        NetworkStatus.Fill = Brushes.Green;
                    }
                });
            });
        }

        protected override void OnClosed(EventArgs e)
        {
            _monitoringService?.Dispose();
            base.OnClosed(e);
        }
    }
} 