import SwiftUI
import SwiftData

struct VenuePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomVenue.name) private var customVenues: [CustomVenue]

    @Binding var selectedVenueID: String?
    var onSelect: (VenueRef?) -> Void

    @State private var searchText = ""
    @State private var showAddCustom = false

    private var catalog: VenueCatalog { .shared }

    private var groups: [(country: String, venues: [VenueRef])] {
        catalog.groupedByCountry(custom: Array(customVenues), query: searchText)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectedVenueID = nil
                        onSelect(nil)
                        dismiss()
                    } label: {
                        HStack {
                            Text("No venue")
                            Spacer()
                            if selectedVenueID == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }

                ForEach(groups, id: \.country) { group in
                    Section(group.country) {
                        ForEach(group.venues) { venue in
                            Button {
                                selectedVenueID = venue.id
                                onSelect(venue)
                                dismiss()
                            } label: {
                                VenueRow(venue: venue, isSelected: selectedVenueID == venue.id)
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Name, city, or country")
            .navigationTitle("Venue")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddCustom = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCustom) {
                CustomVenueFormView { venue in
                    modelContext.insert(venue)
                    try? modelContext.save()
                    let ref = VenueRef.from(venue)
                    selectedVenueID = ref.id
                    onSelect(ref)
                    dismiss()
                }
            }
        }
    }
}

private struct VenueRow: View {
    let venue: VenueRef
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(venue.name)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                    if venue.status == .uncertain {
                        Text("Uncertain")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.25))
                            .clipShape(Capsule())
                    }
                    if venue.isCustom {
                        Text("Custom")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                Text(venue.displaySubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
    }
}
