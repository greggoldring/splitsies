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
    var viewModel: StopwatchViewModel

    var body: some View {
        GeometryReader { geo in
            let total = geo.size.height
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom
            let horizontalPad: CGFloat = 12
            let verticalPad: CGFloat = 12

            // Allocate less height to buttons/bottom so center split time can be as large as possible
            let buttonRowHeight = min(max(88, total * 0.22), 140)
            let bottomSectionHeight: CGFloat = 44
            let centerHeight = max(60, total - safeTop - safeBottom - buttonRowHeight - bottomSectionHeight - verticalPad * 3)

            VStack(spacing: 0) {
                // Top row: Start/Lap and Stop/Reset — as large as the allocated row
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

                // Center: Most recent split — font as large as possible to fill available height
                Text(viewModel.mostRecentSplitDisplay)
                    .font(.custom("SpaceMono-Regular", size: min(340, centerHeight * 0.88)))
                    .minimumScaleFactor(0.35)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: centerHeight)

                Spacer(minLength: verticalPad)

                // Bottom: Running time (compact so center gets space)
                Text(viewModel.runningTimeDisplay)
                    .font(.custom("SpaceMono-Regular", size: 28))
                    .foregroundStyle(.secondary)
                    .frame(height: bottomSectionHeight - verticalPad)
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
        .modelContainer(for: [Item.self, Race.self, Split.self], inMemory: true)
}
