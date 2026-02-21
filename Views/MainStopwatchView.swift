import SwiftUI
import CoreData

struct MainStopwatchView: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var viewModel: StopwatchViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                stopwatchContent(viewModel: vm)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = StopwatchViewModel(context: managedObjectContext)
                    }
            }
        }
    }

    private func stopwatchContent(viewModel: StopwatchViewModel) -> some View {
        VStack(spacing: 0) {
                // Top row: Start/Lap (left) and Stop/Reset (right)
                HStack(spacing: 0) {
                    ActionButton(
                        title: viewModel.startLapButtonTitle,
                        color: .green,
                        action: { viewModel.start() }
                    )
                    Spacer()
                    ActionButton(
                        title: viewModel.stopResetButtonTitle,
                        color: viewModel.isRunning ? .red : .orange,
                        action: { viewModel.stopOrReset() }
                    )
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .frame(height: 100)

                Spacer()

                // Center: Most recent split (very large)
                Text(viewModel.mostRecentSplitDisplay)
                    .font(.custom("Orbitron-Bold", size: 144).monospacedDigit())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)

                Spacer()

                // Bottom-center: Running time
                Text(viewModel.runningTimeDisplay)
                    .font(.custom("Orbitron-Medium", size: 32).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)
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
                .font(.custom("Orbitron-SemiBold", size: 24))
                .foregroundColor(.white)
                .frame(minWidth: 120, minHeight: 120)
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
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
