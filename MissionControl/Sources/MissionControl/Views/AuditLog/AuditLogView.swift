import SwiftUI

struct AuditLogView: View {
    @State private var viewModel = AuditLogViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var scrollProxy: ScrollViewProxy? = nil

    var body: some View {
        VStack(spacing: 0) {
            filterChipBar
            Divider()
                .background(DesignTokens.border(for: colorScheme))
            columnHeader
            Divider()
                .background(DesignTokens.border(for: colorScheme))
            eventList
        }
        .background(DesignTokens.background(for: colorScheme))
        .navigationTitle("Audit Log")
        .toolbar { toolbarContent }
        .task { await viewModel.loadEvents() }
        .overlay {
            if viewModel.isLoading && viewModel.events.isEmpty {
                loadingOverlay
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            // Live/Mock toggle
            Toggle(isOn: Binding(
                get: { viewModel.useLiveData },
                set: { _ in viewModel.toggleDataSource() }
            )) {
                Label(
                    viewModel.useLiveData ? "Live Data" : "Mock Data",
                    systemImage: viewModel.useLiveData ? "antenna.radiowaves.left.and.right" : "doc.text"
                )
            }
            .toggleStyle(.button)
            .tint(viewModel.useLiveData ? DesignTokens.success : DesignTokens.textSecondary)
            .help("Toggle between live JSONL files and mock data")

            // Auto-scroll toggle
            Toggle(isOn: $viewModel.isAutoScrolling) {
                Label("Auto-scroll", systemImage: "arrow.down.to.line")
            }
            .toggleStyle(.button)
            .tint(viewModel.isAutoScrolling ? DesignTokens.accent : DesignTokens.textSecondary)
            .help("Auto-scroll to newest events")

            // Export menu
            Menu {
                Button {
                    exportAndReveal(format: .json)
                } label: {
                    Label("Export as JSON", systemImage: "doc.text")
                }
                Button {
                    exportAndReveal(format: .csv)
                } label: {
                    Label("Export as CSV", systemImage: "tablecells")
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .help("Export filtered events")
        }

        ToolbarItem(placement: .automatic) {
            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DesignTokens.textSecondary)
                    .font(.system(size: 13))
                TextField("Search events...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .font(DesignTokens.Typography.body)
                    .frame(width: 200)
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignTokens.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DesignTokens.surface(for: colorScheme))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DesignTokens.border(for: colorScheme), lineWidth: 1)
            )
        }
    }

    // MARK: - Filter Chip Bar

    private var filterChipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                filterChip(
                    label: "All",
                    color: DesignTokens.textSecondary,
                    isSelected: viewModel.selectedEventTypes.isEmpty
                ) {
                    viewModel.selectedEventTypes = []
                }

                ForEach(AuditEventType.allCases, id: \.self) { eventType in
                    filterChip(
                        label: eventType.displayName,
                        color: eventType.color,
                        isSelected: viewModel.selectedEventTypes.contains(eventType)
                    ) {
                        if viewModel.selectedEventTypes.contains(eventType) {
                            viewModel.selectedEventTypes.remove(eventType)
                        } else {
                            viewModel.selectedEventTypes.insert(eventType)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(DesignTokens.surface(for: colorScheme).opacity(0.5))
    }

    private func filterChip(label: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isSelected {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                }
                Text(label)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(isSelected ? color : DesignTokens.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? color.opacity(0.12) : DesignTokens.surface(for: colorScheme))
            .cornerRadius(20)
            .overlay(
                Capsule()
                    .stroke(isSelected ? color.opacity(0.6) : DesignTokens.border(for: colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Column Header

    private var columnHeader: some View {
        HStack(spacing: 10) {
            Text("")
                .frame(width: 12)
            Text("Timestamp")
                .frame(width: 90, alignment: .leading)
            Text("Task ID")
                .frame(width: 150, alignment: .leading)
            Text("Event Type")
                .frame(width: 120, alignment: .leading)
            Text("Data")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Duration")
                .frame(width: 65, alignment: .trailing)
        }
        .font(DesignTokens.Typography.caption)
        .foregroundStyle(DesignTokens.textSecondary)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(DesignTokens.surface(for: colorScheme).opacity(0.5))
    }

    // MARK: - Event List

    private var eventList: some View {
        ScrollViewReader { proxy in
            List {
                if viewModel.filteredEvents.isEmpty && !viewModel.isLoading {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.filteredEvents) { event in
                        AuditEventRow(event: event)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.visible)
                            .listRowInsets(EdgeInsets())
                            .id(event.id)
                    }
                }
            }
            .listStyle(.plain)
            .background(DesignTokens.background(for: colorScheme))
            .onChange(of: viewModel.filteredEvents.count) { _, _ in
                if viewModel.isAutoScrolling, let last = viewModel.filteredEvents.first {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .top)
                    }
                }
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(DesignTokens.textSecondary.opacity(0.5))
            Text(viewModel.searchQuery.isEmpty && viewModel.selectedEventTypes.isEmpty
                 ? "No audit events"
                 : "No matching events")
                .font(DesignTokens.Typography.subheading)
                .foregroundStyle(DesignTokens.textSecondary)
            if !viewModel.searchQuery.isEmpty || !viewModel.selectedEventTypes.isEmpty {
                Button("Clear Filters") {
                    viewModel.searchQuery = ""
                    viewModel.selectedEventTypes = []
                }
                .buttonStyle(.bordered)
                .tint(DesignTokens.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading events...")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.background(for: colorScheme).opacity(0.8))
    }

    // MARK: - Export

    private func exportAndReveal(format: AuditLogViewModel.ExportFormat) {
        let url = viewModel.exportEvents(format: format)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

#Preview {
    AuditLogView()
        .environment(AppState())
        .frame(width: 1000, height: 700)
}
