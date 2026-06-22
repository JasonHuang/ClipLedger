import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var viewModel: ClipboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            settingsHeader

            ScrollView {
                VStack(spacing: 14) {
                    SettingsGroup(title: "General", systemImage: "power") {
                        Toggle("Launch at login", isOn: $settings.launchAtLoginEnabled)
                    }

                    SettingsGroup(title: "History", systemImage: "clock.arrow.circlepath") {
                        VStack(alignment: .leading, spacing: 9) {
                            Text("Maximum record count")
                                .font(.callout.weight(.medium))

                            Picker("Maximum record count", selection: $settings.maximumHistoryCount) {
                                ForEach(AppSettings.historyCountOptions, id: \.self) { option in
                                    Text("\(option)").tag(option)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                        }

                        Divider()

                        Toggle("Remove consecutive duplicates", isOn: $settings.removeConsecutiveDuplicates)
                    }

                    SettingsGroup(title: "Behavior", systemImage: "pin") {
                        HStack {
                            Text("Auto pin threshold")
                                .font(.callout.weight(.medium))

                            Spacer()

                            Text("\(AppSettings.autoPinThreshold) uses")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(Capsule())
                        }
                    }

                    SettingsGroup(title: "Privacy", systemImage: "lock.shield") {
                        Text("ClipLedger stores clipboard history locally on your Mac and never transmits clipboard data externally.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
            }
        }
        .frame(width: 520, height: 440)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.42))
        .onChange(of: settings.maximumHistoryCount) {
            viewModel.enforceHistoryLimitAndReload()
        }
    }

    private var settingsHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.16))

                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.title3.weight(.semibold))
                Text("ClipLedger")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(.regularMaterial)
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                Text(title)
                    .font(.subheadline.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.10))
            }
        }
    }
}
