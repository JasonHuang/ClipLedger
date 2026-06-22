import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var viewModel: ClipboardViewModel

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $settings.launchAtLoginEnabled)
            }

            Section("History") {
                Picker("Maximum record count", selection: $settings.maximumHistoryCount) {
                    ForEach(AppSettings.historyCountOptions, id: \.self) { option in
                        Text("\(option)").tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Remove consecutive duplicates", isOn: $settings.removeConsecutiveDuplicates)
            }

            Section("Behavior") {
                LabeledContent("Auto pin threshold", value: "\(AppSettings.autoPinThreshold) uses")
            }

            Section("Privacy") {
                Text("ClipLedger stores clipboard history locally on your Mac and never transmits clipboard data externally.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 460, height: 360)
        .onChange(of: settings.maximumHistoryCount) {
            viewModel.enforceHistoryLimitAndReload()
        }
    }
}
