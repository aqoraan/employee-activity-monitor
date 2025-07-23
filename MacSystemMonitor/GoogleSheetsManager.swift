import Foundation

class GoogleSheetsManager {
    private let apiKey: String
    private let spreadsheetId: String
    private let range: String
    private var cache: [String] = []
    private var lastCacheUpdate: Date?
    private let cacheExpirationMinutes: Int
    
    init(apiKey: String, spreadsheetId: String, range: String, cacheExpirationMinutes: Int = 5) {
        self.apiKey = apiKey
        self.spreadsheetId = spreadsheetId
        self.range = range
        self.cacheExpirationMinutes = cacheExpirationMinutes
    }
    
    // MARK: - USB Whitelist Management
    
    func getWhitelistedDevices() async -> [String] {
        // Check cache first
        if isCacheValid() {
            return cache
        }
        
        // Fetch from Google Sheets
        do {
            let devices = try await fetchWhitelistFromGoogleSheets()
            updateCache(with: devices)
            return devices
        } catch {
            print("Failed to fetch whitelist from Google Sheets: \(error)")
            return cache // Return cached data if available
        }
    }
    
    func isDeviceWhitelisted(_ deviceId: String) async -> Bool {
        let whitelistedDevices = await getWhitelistedDevices()
        return whitelistedDevices.contains { deviceId.lowercased().contains($0.lowercased()) }
    }
    
    // MARK: - Google Sheets API Integration
    
    private func fetchWhitelistFromGoogleSheets() async throws -> [String] {
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range)?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw GoogleSheetsError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleSheetsError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GoogleSheetsError.httpError(httpResponse.statusCode)
        }
        
        let sheetsResponse = try JSONDecoder().decode(GoogleSheetsResponse.self, from: data)
        return parseWhitelistFromResponse(sheetsResponse)
    }
    
    private func parseWhitelistFromResponse(_ response: GoogleSheetsResponse) -> [String] {
        var devices: [String] = []
        
        for row in response.values {
            if let deviceId = row.first, !deviceId.isEmpty {
                // Clean up the device ID (remove quotes, trim whitespace)
                let cleanDeviceId = deviceId.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\"", with: "")
                
                if !cleanDeviceId.isEmpty && !cleanDeviceId.hasPrefix("#") {
                    devices.append(cleanDeviceId)
                }
            }
        }
        
        return devices
    }
    
    // MARK: - Cache Management
    
    private func isCacheValid() -> Bool {
        guard let lastUpdate = lastCacheUpdate else {
            return false
        }
        
        let expirationInterval = TimeInterval(cacheExpirationMinutes * 60)
        return Date().timeIntervalSince(lastUpdate) < expirationInterval
    }
    
    private func updateCache(with devices: [String]) {
        cache = devices
        lastCacheUpdate = Date()
    }
    
    // MARK: - Device ID Normalization
    
    func normalizeDeviceId(_ deviceId: String) -> String {
        // Remove common prefixes and normalize format
        var normalized = deviceId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common USB prefixes
        let prefixes = ["USB\\", "usb\\", "USB:", "usb:"]
        for prefix in prefixes {
            if normalized.hasPrefix(prefix) {
                normalized = String(normalized.dropFirst(prefix.count))
                break
            }
        }
        
        // Normalize separators
        normalized = normalized.replacingOccurrences(of: "\\", with: "&")
        normalized = normalized.replacingOccurrences(of: ":", with: "&")
        
        return normalized.uppercased()
    }
    
    // MARK: - Error Handling
    
    enum GoogleSheetsError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case httpError(Int)
        case decodingError
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid Google Sheets URL"
            case .invalidResponse:
                return "Invalid response from Google Sheets API"
            case .httpError(let code):
                return "HTTP error: \(code)"
            case .decodingError:
                return "Failed to decode Google Sheets response"
            case .noData:
                return "No data received from Google Sheets"
            }
        }
    }
}

// MARK: - Google Sheets Response Models

struct GoogleSheetsResponse: Codable {
    let range: String
    let majorDimension: String
    let values: [[String]]
}

// MARK: - USB Device Information

struct UsbDeviceInfo {
    let deviceId: String
    let vendorId: String?
    let productId: String?
    let deviceName: String?
    let serialNumber: String?
    
    var normalizedDeviceId: String {
        return GoogleSheetsManager(apiKey: "", spreadsheetId: "", range: "").normalizeDeviceId(deviceId)
    }
}

// MARK: - Whitelist Validation

extension GoogleSheetsManager {
    func validateWhitelistFormat(_ devices: [String]) -> [String] {
        return devices.filter { device in
            // Basic validation for USB device ID format
            let normalized = normalizeDeviceId(device)
            return normalized.contains("VID_") && normalized.contains("PID_")
        }
    }
    
    func getWhitelistStatistics() -> (total: Int, valid: Int, invalid: Int) {
        let total = cache.count
        let valid = validateWhitelistFormat(cache).count
        let invalid = total - valid
        
        return (total: total, valid: valid, invalid: invalid)
    }
}

// MARK: - Async Support for Legacy Code

extension GoogleSheetsManager {
    func getWhitelistedDevicesSync() -> [String] {
        let semaphore = DispatchSemaphore(value: 0)
        var result: [String] = []
        
        Task {
            result = await getWhitelistedDevices()
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    func isDeviceWhitelistedSync(_ deviceId: String) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var result = false
        
        Task {
            result = await isDeviceWhitelisted(deviceId)
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
} 