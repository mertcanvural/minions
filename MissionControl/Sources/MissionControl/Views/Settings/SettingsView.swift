import SwiftUI
import AppKit

struct SettingsView: View {

    // MARK: - Persistent Settings (@AppStorage)

    @AppStorage("settings.bridgeURL") private var bridgeURL: String = "http://localhost:8080"
    @AppStorage("settings.apiKey") private var apiKey: String = ""
    @AppStorage("settings.dashboardRefreshInterval") private var dashboardRefreshInterval: Double = 10
    @AppStorage("settings.auditRefreshInterval") private var auditRefreshInterval: Double = 5
    @AppStorage("settings.themeRaw") private var themeRaw: String = AppState.ThemePreference.system.rawValue
    @AppStorage("settings.auditPath") private var auditPath: String = ""
    @AppStorage("settings.terminalPreference") private var terminalPreference: String = "auto"
    @AppStorage("settings.maxAuditEvents") private var maxAuditEvents: Int = 500
    @AppStorage("settings.debugLogging") private var debugLogging: Bool = false
    @AppStorage("settings.selectedAccentIndex") private var selectedAccentIndex: Int = 0

    // MARK: - ViewModel (for business logic: testConnection, detectTerminal)

    @State private var vm = SettingsViewModel()

    // MARK: - UI State

    @State private var showResetAlert = false
    @State private var sectionsAppeared = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Accent Presets

    private let accentPresets: [(color: Color, name: String)] = [
        (Color(red: 0.39, green: 0.41, blue: 0.95), "Indigo"),
        (Color(red: 0.59, green: 0.31, blue: 0.95), "Purple"),
        (Color(red: 0.14, green: 0.69, blue: 0.93), "Cyan"),
        (Color(red: 0.13, green: 0.77, blue: 0.30), "Green"),
        (Color(red: 0.96, green: 0.62, blue: 0.04), "Amber"),
    ]

    private var defaultAuditPath: String {
        "\(NSHomeDirectory())/.minion/audit"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sectionSpacing) {

                // Header
                Text("Settings")
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))

                // Connection Section
                settingsSection(title: "Connection", icon: "network") {
                    VStack(spacing: 12) {
                        settingsRow(label: "Bridge URL") {
                            TextField("http://localhost:8080", text: $bridgeURL)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 320)
                        }
                        Divider()
                        settingsRow(label: "API Key") {
                            SecureField("Optional", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 320)
                        }
                        Divider()
                        HStack(spacing: 12) {
                            Button("Test Connection") {
                                vm.bridgeURL = bridgeURL
                                vm.apiKey = apiKey
                                Task { await vm.testConnection() }
                            }
                            .buttonStyle(.bordered)
                            .disabled(vm.isTestingConnection)

                            Group {
                                if vm.isTestingConnection {
                                    ProgressView()
                                        .controlSize(.small)
                                        .transition(.opacity)
                                } else if let result = vm.connectionTestResult {
                                    HStack(spacing: 6) {
                                        Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(result.isSuccess ? DesignTokens.success : DesignTokens.failure)
                                        Text(result.message)
                                            .font(DesignTokens.Typography.caption)
                                            .foregroundStyle(DesignTokens.textSecondary)
                                    }
                                    .transition(.opacity)
                                }
                            }
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: vm.connectionTestResult != nil)
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: vm.isTestingConnection)
                            Spacer()
                        }
                    }
                }

                // Refresh Section
                settingsSection(title: "Refresh Intervals", icon: "arrow.clockwise") {
                    VStack(spacing: 16) {
                        intervalRow(
                            label: "Dashboard",
                            value: $dashboardRefreshInterval,
                            range: 5...60,
                            step: 5
                        )
                        Divider()
                        intervalRow(
                            label: "Audit Log",
                            value: $auditRefreshInterval,
                            range: 1...30,
                            step: 1
                        )
                    }
                }

                // Appearance Section
                settingsSection(title: "Appearance", icon: "paintpalette") {
                    VStack(spacing: 12) {
                        settingsRow(label: "Theme") {
                            Picker("", selection: $themeRaw) {
                                Text("Dark").tag(AppState.ThemePreference.dark.rawValue)
                                Text("Light").tag(AppState.ThemePreference.light.rawValue)
                                Text("System").tag(AppState.ThemePreference.system.rawValue)
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 240)
                            .labelsHidden()
                        }
                        Divider()
                        settingsRow(label: "Accent Color") {
                            HStack(spacing: 10) {
                                ForEach(accentPresets.indices, id: \.self) { index in
                                    accentSwatch(
                                        color: accentPresets[index].color,
                                        name: accentPresets[index].name,
                                        isSelected: selectedAccentIndex == index
                                    ) {
                                        selectedAccentIndex = index
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }

                // Audit Section
                settingsSection(title: "Audit Log", icon: "doc.text.magnifyingglass") {
                    VStack(spacing: 12) {
                        settingsRow(label: "Audit Directory") {
                            HStack(spacing: 8) {
                                TextField(defaultAuditPath, text: $auditPath)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 280)
                                Button(action: chooseAuditFolder) {
                                    Image(systemName: "folder")
                                }
                                .buttonStyle(.bordered)
                                .help("Choose directory")
                            }
                        }
                        Divider()
                        settingsRow(label: "Max Events") {
                            HStack(spacing: 12) {
                                Stepper(
                                    value: $maxAuditEvents,
                                    in: 100...5000,
                                    step: 100
                                ) {
                                    EmptyView()
                                }
                                .labelsHidden()
                                Text("\(maxAuditEvents)")
                                    .font(DesignTokens.Typography.code)
                                    .foregroundStyle(DesignTokens.accent)
                                    .frame(minWidth: 48, alignment: .leading)
                                Spacer()
                            }
                        }
                    }
                }

                // Terminal Section
                settingsSection(title: "Terminal", icon: "terminal") {
                    VStack(spacing: 12) {
                        settingsRow(label: "Detected Terminal") {
                            Text(vm.detectTerminal())
                                .font(DesignTokens.Typography.code)
                                .foregroundStyle(DesignTokens.textSecondary)
                        }
                        Divider()
                        settingsRow(label: "Override") {
                            Picker("", selection: $terminalPreference) {
                                Text("Auto Detect").tag("auto")
                                Text("Terminal.app").tag("Terminal")
                                Text("iTerm2").tag("iTerm2")
                                Text("Warp").tag("Warp")
                                Text("Ghostty").tag("Ghostty")
                            }
                            .frame(maxWidth: 200)
                            .labelsHidden()
                        }
                    }
                }

                // Advanced Section
                settingsSection(title: "Advanced", icon: "wrench.and.screwdriver") {
                    VStack(spacing: 12) {
                        settingsRow(label: "Debug Logging") {
                            Toggle("", isOn: $debugLogging)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .tint(DesignTokens.accent)
                        }
                        Divider()
                        HStack {
                            Button("Reset to Defaults") {
                                showResetAlert = true
                            }
                            .foregroundStyle(DesignTokens.failure)
                            .buttonStyle(.plain)
                            Spacer()
                        }
                    }
                }

                // Save Button
                HStack {
                    Spacer()
                    Button(action: {
                        Task { await saveSettings() }
                    }) {
                        HStack(spacing: 8) {
                            if vm.isSaving {
                                ProgressView().controlSize(.small)
                            }
                            Text(vm.isSaving ? "Saving..." : "Save Settings")
                        }
                        .frame(minWidth: 140)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DesignTokens.accent)
                    .disabled(vm.isSaving)
                    .controlSize(.large)
                }
                .padding(.top, 8)
            }
            .padding(DesignTokens.Spacing.sectionSpacing)
            .opacity(sectionsAppeared ? 1 : 0)
            .offset(y: sectionsAppeared ? 0 : 16)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: sectionsAppeared)
        }
        .background(DesignTokens.background(for: colorScheme))
        .onAppear {
            if auditPath.isEmpty {
                auditPath = defaultAuditPath
            }
            guard !reduceMotion else {
                sectionsAppeared = true
                return
            }
            withAnimation(.easeInOut(duration: 0.4)) {
                sectionsAppeared = true
            }
        }
        .alert("Reset to Defaults", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
    }

    // MARK: - Helper Views

    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.accent)
                Text(title)
                    .font(DesignTokens.Typography.subheading)
                    .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
            }
            .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(DesignTokens.Spacing.cardPadding)
            .background(DesignTokens.surface(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius)
                    .strokeBorder(DesignTokens.border(for: colorScheme), lineWidth: 1)
            )
            .cardShadow()
        }
    }

    private func settingsRow<Content: View>(
        label: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
                .frame(minWidth: 140, alignment: .leading)
            control()
        }
    }

    private func intervalRow(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
                Spacer()
                Text("\(Int(value.wrappedValue))s")
                    .font(DesignTokens.Typography.code)
                    .foregroundStyle(DesignTokens.accent)
                    .frame(minWidth: 40, alignment: .trailing)
            }
            Slider(value: value, in: range, step: step)
                .tint(DesignTokens.accent)
        }
    }

    private func accentSwatch(
        color: Color,
        name: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 2.5)
                        .frame(width: 28, height: 28)
                    Circle()
                        .strokeBorder(color, lineWidth: 1)
                        .frame(width: 34, height: 34)
                }
            }
        }
        .buttonStyle(.plain)
        .shadow(color: isSelected ? color.opacity(0.5) : .clear, radius: 6)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .help(name)
    }

    // MARK: - Actions

    private func saveSettings() async {
        vm.bridgeURL = bridgeURL
        vm.apiKey = apiKey
        vm.dashboardRefreshInterval = dashboardRefreshInterval
        vm.auditRefreshInterval = auditRefreshInterval
        vm.theme = AppState.ThemePreference(rawValue: themeRaw) ?? .system
        vm.auditPath = auditPath
        vm.terminalPreference = terminalPreference
        vm.debugLogging = debugLogging
        await vm.save()
    }

    private func resetToDefaults() {
        bridgeURL = "http://localhost:8080"
        apiKey = ""
        dashboardRefreshInterval = 10
        auditRefreshInterval = 5
        themeRaw = AppState.ThemePreference.system.rawValue
        auditPath = defaultAuditPath
        terminalPreference = "auto"
        maxAuditEvents = 500
        debugLogging = false
        selectedAccentIndex = 0
        vm.connectionTestResult = nil
    }

    private func chooseAuditFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.title = "Select Audit Log Directory"
        panel.directoryURL = URL(fileURLWithPath: auditPath.isEmpty ? defaultAuditPath : auditPath)

        if panel.runModal() == .OK, let url = panel.url {
            auditPath = url.path
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .frame(width: 700, height: 800)
}
