import Foundation

protocol WeatherProviding {
    /// Returns a short Mandarin weather summary such as "晴天", "多云", "小雨".
    /// Return nil if unavailable.
    func fetchWeatherSummary(for date: Date) async -> String?
}

/// Default placeholder provider to avoid blocking main feature.
/// Thread C uses it; later you can replace with WeatherKit provider in a new thread.
struct PlaceholderWeatherProvider: WeatherProviding {
    let fixedText: String?

    init(fixedText: String? = nil) {
        self.fixedText = fixedText
    }

    func fetchWeatherSummary(for date: Date) async -> String? {
        // Keep it nil by default; you can set fixedText during dev/test.
        return fixedText
    }
}
