using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using Newtonsoft.Json;
using System.Linq;

namespace SystemMonitor
{
    public class GoogleSheetsManager
    {
        private readonly HttpClient _httpClient;
        private readonly string _apiKey;
        private readonly string _spreadsheetId;
        private readonly string _range;
        private List<string> _whitelistedUsbIds;
        private DateTime _lastCacheUpdate;
        private readonly TimeSpan _cacheExpiration = TimeSpan.FromMinutes(5);

        public GoogleSheetsManager(string apiKey, string spreadsheetId, string range = "A:A")
        {
            _httpClient = new HttpClient();
            _apiKey = apiKey;
            _spreadsheetId = spreadsheetId;
            _range = range;
            _whitelistedUsbIds = new List<string>();
            _lastCacheUpdate = DateTime.MinValue;
        }

        public async Task<bool> IsUsbWhitelisted(string usbId)
        {
            try
            {
                // Update cache if needed
                if (DateTime.Now - _lastCacheUpdate > _cacheExpiration)
                {
                    await UpdateWhitelistCache();
                }

                // Check if USB ID is in whitelist
                return _whitelistedUsbIds.Any(id => 
                    id.Equals(usbId, StringComparison.OrdinalIgnoreCase) ||
                    usbId.Contains(id, StringComparison.OrdinalIgnoreCase));
            }
            catch (Exception ex)
            {
                // Log error but don't block USB if we can't verify
                System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                    $"Failed to check USB whitelist: {ex.Message}", 
                    System.Diagnostics.EventLogEntryType.Warning);
                return true; // Allow USB if we can't verify
            }
        }

        private async Task UpdateWhitelistCache()
        {
            try
            {
                var url = $"https://sheets.googleapis.com/v4/spreadsheets/{_spreadsheetId}/values/{_range}?key={_apiKey}";
                
                var response = await _httpClient.GetAsync(url);
                if (response.IsSuccessStatusCode)
                {
                    var content = await response.Content.ReadAsStringAsync();
                    var result = JsonConvert.DeserializeObject<GoogleSheetsResponse>(content);
                    
                    _whitelistedUsbIds.Clear();
                    if (result?.Values != null)
                    {
                        foreach (var row in result.Values)
                        {
                            if (row.Length > 0 && !string.IsNullOrWhiteSpace(row[0]))
                            {
                                _whitelistedUsbIds.Add(row[0].Trim());
                            }
                        }
                    }
                    
                    _lastCacheUpdate = DateTime.Now;
                    
                    System.Diagnostics.EventLog.WriteEntry("EmployeeActivityMonitor", 
                        $"USB whitelist updated: {_whitelistedUsbIds.Count} entries", 
                        System.Diagnostics.EventLogEntryType.Information);
                }
                else
                {
                    throw new Exception($"Google Sheets API returned {response.StatusCode}");
                }
            }
            catch (Exception ex)
            {
                throw new Exception($"Failed to update USB whitelist: {ex.Message}");
            }
        }

        public List<string> GetWhitelistedUsbIds()
        {
            return new List<string>(_whitelistedUsbIds);
        }

        public void Dispose()
        {
            _httpClient?.Dispose();
        }
    }

    public class GoogleSheetsResponse
    {
        [JsonProperty("values")]
        public string[][] Values { get; set; }
    }
} 