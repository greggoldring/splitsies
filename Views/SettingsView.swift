import SwiftUI

struct SettingsView: View {
    @AppStorage("settings.pressureUnit") private var pressureUnitRaw: String = PressureUnit.hPa.rawValue
    @AppStorage("settings.weatherAPIEnabled") private var weatherAPIEnabled: Bool = true

    private var pressureUnit: Binding<PressureUnit> {
        Binding(
            get: { PressureUnit(rawValue: pressureUnitRaw) ?? .hPa },
            set: { pressureUnitRaw = $0.rawValue; AppSettings.pressureUnit = $0 }
        )
    }

    var body: some View {
        Form {
            Section {
                Picker("Pressure unit", selection: pressureUnit) {
                    ForEach(PressureUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
            } header: {
                Text("Display")
            } footer: {
                Text("Storage is always in hPa. This only changes how pressure is shown.")
            }

            Section {
                Toggle("Weather API lookups", isOn: Binding(
                    get: { weatherAPIEnabled },
                    set: { weatherAPIEnabled = $0; AppSettings.weatherAPIEnabled = $0 }
                ))
            } header: {
                Text("Privacy & Offline")
            } footer: {
                Text("When off, Splitsies will not fetch Open-Meteo pressure for venues. The barometer still works offline.")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
