import SwiftUI

struct ConditionsChipView: View {
    let stationPressureHPa: Double?
    let pressureSource: PressureSource
    let pending: Bool
    let temperatureC: Double?
    let relativeHumidityPct: Double?
    let elevationM: Double?
    let venueName: String?

    @State private var showDetail = false
    @AppStorage("settings.pressureUnit") private var pressureUnitRaw: String = PressureUnit.hPa.rawValue

    private var unit: PressureUnit {
        PressureUnit(rawValue: pressureUnitRaw) ?? .hPa
    }

    private var chipText: String {
        PressureFormatting.pressureChip(
            hPa: stationPressureHPa,
            source: pressureSource,
            unit: unit,
            pending: pending
        )
    }

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "barometer")
                    .font(.caption)
                Text(chipText)
                    .font(.custom("SpaceMono-Regular", size: 13))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showDetail, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
            ConditionsDetailView(
                stationPressureHPa: stationPressureHPa,
                pressureSource: pressureSource,
                pending: pending,
                temperatureC: temperatureC,
                relativeHumidityPct: relativeHumidityPct,
                elevationM: elevationM,
                venueName: venueName,
                unit: unit
            )
            .padding()
            .frame(minWidth: 260)
            .presentationCompactAdaptation(.popover)
        }
    }
}

struct ConditionsDetailView: View {
    let stationPressureHPa: Double?
    let pressureSource: PressureSource
    let pending: Bool
    let temperatureC: Double?
    let relativeHumidityPct: Double?
    let elevationM: Double?
    let venueName: String?
    let unit: PressureUnit

    private var seaLevel: Double? {
        guard let stationPressureHPa else { return nil }
        return PressureMath.seaLevelPressure(
            stationHPa: stationPressureHPa,
            elevationM: elevationM,
            temperatureC: temperatureC
        )
    }

    private var density: Double? {
        guard let stationPressureHPa else { return nil }
        return PressureMath.airDensity(
            stationHPa: stationPressureHPa,
            temperatureC: temperatureC,
            relativeHumidityPct: relativeHumidityPct
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Conditions")
                .font(.headline)

            row("Venue", venueName ?? "No venue")
            row("Station pressure", stationPressureHPa.map { unit.format($0) } ?? (pending ? "Pending" : "—"))
            row("Sea-level pressure", seaLevel.map { unit.format($0) } ?? "—")
            row("Temperature", temperatureC.map { String(format: "%.1f °C", $0) } ?? "—")
            row("Humidity", relativeHumidityPct.map { String(format: "%.0f%%", $0) } ?? "—")
            row("Air density", density.map { PressureFormatting.density($0) } ?? "—")
            row("Source", PressureFormatting.sourceLabel(pressureSource))
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.custom("SpaceMono-Regular", size: 13))
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
