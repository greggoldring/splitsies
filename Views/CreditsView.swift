//
//  CreditsView.swift
//  Splitsies
//
//  Created by Gregg Oldring on 2026-02-14.
//

import SwiftUI

struct CreditsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Splitsies")
                    .font(.title.bold())
                Text("Version \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("© 2026 Gregg Goldring")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                Text("Typography")
                    .font(.headline)
                Text("Space Mono")
                    .font(.subheadline.bold())
                Text("Designed by Colophon Foundry. This Font Software is licensed under the SIL Open Font License, Version 1.1.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Credits")
    }
}

private extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    NavigationStack {
        CreditsView()
    }
}
