import SwiftUI
import SwiftData

struct MainStopwatchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StopwatchViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                StopwatchContentView(viewModel: vm)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = StopwatchViewModel(modelContext: modelContext)
                    }
            }
        }
    }
}

/// Separate view so SwiftUI subscribes to @Observable view model updates (timer, splits, etc.)
private struct StopwatchContentView: View {
    @Bindable var viewModel: StopwatchViewModel
    @State private var selectedVenueID: String?
    @State private var showVenuePicker = false

    var body: some View {
        GeometryReader { geo in
            let total = geo.size.height
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom
            let horizontalPad: CGFloat = 12
            let verticalPad: CGFloat = 8

            let buttonRowHeight = min(max(88, total * 0.20), 140)
            let metaRowHeight: CGFloat = 36
            let bottomSectionHeight: CGFloat = 44
            let centerHeight = max(
                60,
                total - safeTop - safeBottom - buttonRowHeight - metaRowHeight - bottomSectionHeight - verticalPad * 4
            )

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ActionButton(
                        title: viewModel.startLapButtonTitle,
                        color: .green,
                        action: { viewModel.start() }
                    )
                    ActionButton(
                        title: viewModel.stopResetButtonTitle,
                        color: viewModel.isRunning ? .red : .orange,
                        action: { viewModel.stopOrReset() }
                    )
                }
                .padding(.horizontal, horizontalPad)
                .padding(.top, verticalPad)
                .frame(height: buttonRowHeight)

                Spacer(minLength: verticalPad)

                Text(viewModel.mostRecentSplitDisplay)
                    .font(.custom("SpaceMono-Regular", size: min(340, centerHeight * 0.88)))
                    .minimumScaleFactor(0.2)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: centerHeight)

                // Venue + conditions
                HStack(spacing: 8) {
                    Button {
                        selectedVenueID = viewModel.selectedVenue?.id
                        showVenuePicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.caption)
                            Text(viewModel.selectedVenue?.name ?? "No venue")
                                .font(.caption)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isRunning)

                    Spacer(minLength: 0)

                    ConditionsChipView(
                        stationPressureHPa: viewModel.livePressureHPa,
                        pressureSource: viewModel.livePressureSource,
                        pending: viewModel.isPressurePending,
                        temperatureC: viewModel.currentSplits.last?.temperatureC,
                        relativeHumidityPct: viewModel.currentSplits.last?.relativeHumidityPct,
                        elevationM: viewModel.selectedVenue?.elevationM,
                        venueName: viewModel.selectedVenue?.name
                    )
                }
                .padding(.horizontal, horizontalPad)
                .frame(height: metaRowHeight)

                Spacer(minLength: verticalPad)

                Text(viewModel.runningTimeDisplay)
                    .font(.custom("SpaceMono-Regular", size: 28))
                    .foregroundStyle(.secondary)
                    .frame(height: bottomSectionHeight - verticalPad)
            }
        }
        .sheet(isPresented: $showVenuePicker) {
            VenuePickerView(selectedVenueID: $selectedVenueID) { venue in
                viewModel.selectVenue(venue)
            }
        }
    }
}

private struct ActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("SpaceMono-Bold", size: 26))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .overlay(color.opacity(0.45))
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainStopwatchView()
        .modelContainer(for: [Item.self, Race.self, Split.self, CustomVenue.self], inMemory: true)
}

#if DEBUG
#Preview("Stopwatch 2:26.11 - iPhone", traits: .fixedLayout(width: 428, height: 926)) {
    StopwatchPreviewFixture(lapDuration: 146.1101)
}

#Preview("Stopwatch 2:26.11 - iPad Landscape", traits: .fixedLayout(width: 1366, height: 1024)) {
    StopwatchPreviewFixture(lapDuration: 146.1101)
}

@MainActor
private struct StopwatchPreviewFixture: View {
    private let container: ModelContainer
    @State private var viewModel: StopwatchViewModel

    init(lapDuration: TimeInterval) {
        let schema = Schema([
            Item.self,
            Race.self,
            Split.self,
            CustomVenue.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let venue = VenueRef(
                id: "preview-burnaby-velodrome",
                name: "Burnaby Velodrome",
                city: "Burnaby",
                region: "BC",
                country: "Canada",
                countryCode: "CA",
                latitude: 49.2306,
                longitude: -122.9630,
                elevationM: 120,
                indoor: true,
                status: .active,
                isCustom: false
            )
            let viewModel = StopwatchViewModel(
                modelContext: container.mainContext,
                barometer: MockBarometerService(pressureHPa: 934.9)
            )
            viewModel.isRunning = true
            viewModel.startTime = Date(timeIntervalSinceNow: -lapDuration)
            viewModel.displayTime = lapDuration
            viewModel.selectedVenue = venue
            viewModel.currentSplits = [
                StopwatchViewModel.SplitData(
                    lapNumber: 1,
                    splitTime: lapDuration,
                    lapDuration: lapDuration,
                    capturedAt: .now,
                    stationPressureHPa: 934.9,
                    pressureSource: .barometer,
                    venueID: venue.id,
                    temperatureC: 21,
                    relativeHumidityPct: 48
                )
            ]

            self.container = container
            _viewModel = State(initialValue: viewModel)
        } catch {
            fatalError("Could not create stopwatch preview: \(error)")
        }
    }

    var body: some View {
        StopwatchContentView(viewModel: viewModel)
            .modelContainer(container)
            .preferredColorScheme(.dark)
    }
}
#endif
