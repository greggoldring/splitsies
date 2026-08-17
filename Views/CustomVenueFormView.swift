import SwiftUI

struct CustomVenueFormView: View {
    @Environment(\.dismiss) private var dismiss

    var onSave: (CustomVenue) -> Void

    @State private var name = ""
    @State private var city = ""
    @State private var country = ""
    @State private var latitudeText = ""
    @State private var longitudeText = ""
    @State private var elevationText = ""
    @State private var indoor = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Venue") {
                    TextField("Name", text: $name)
                    TextField("City (optional)", text: $city)
                    TextField("Country (optional)", text: $country)
                    Toggle("Indoor", isOn: $indoor)
                }
                Section("Location (optional)") {
                    TextField("Latitude", text: $latitudeText)
                        .keyboardType(.decimalPad)
                    TextField("Longitude", text: $longitudeText)
                        .keyboardType(.decimalPad)
                    TextField("Elevation m", text: $elevationText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Custom Venue")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let venue = CustomVenue(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            country: country.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: Double(latitudeText),
            longitude: Double(longitudeText),
            elevationM: Double(elevationText),
            indoor: indoor
        )
        onSave(venue)
        dismiss()
    }
}
