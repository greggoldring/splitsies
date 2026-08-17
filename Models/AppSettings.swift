import Foundation

/// User preferences for atmospheric display and weather lookups.
enum AppSettings {
    private static let pressureUnitKey = "settings.pressureUnit"
    private static let weatherAPIEnabledKey = "settings.weatherAPIEnabled"
    private static let lastUsedVenueIDKey = "settings.lastUsedVenueID"

    static var pressureUnit: PressureUnit {
        get {
            guard let raw = UserDefaults.standard.string(forKey: pressureUnitKey),
                  let unit = PressureUnit(rawValue: raw) else {
                return .hPa
            }
            return unit
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: pressureUnitKey)
        }
    }

    /// When false, Open-Meteo lookups and backfill are skipped. Default: on.
    static var weatherAPIEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: weatherAPIEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: weatherAPIEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: weatherAPIEnabledKey)
        }
    }

    static var lastUsedVenueID: String? {
        get { UserDefaults.standard.string(forKey: lastUsedVenueIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastUsedVenueIDKey) }
    }
}
