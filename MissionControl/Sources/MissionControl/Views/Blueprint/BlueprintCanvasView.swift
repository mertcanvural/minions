import SwiftUI

// MARK: - Blueprint Canvas View

struct BlueprintCanvasView: View {
    @Bindable var viewModel: BlueprintViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var magnification: CGFloat = 1.0
    @State private var steadyStateMagnification: CGFloat = 1.0
    @State private var mouseOffset: CGSize = .zero
    @State private var scrollProxy: ScrollViewProxy?
    @State private var previousActiveNodeIndex: Int = 0

    private var layouts: [NodeLayout] {
        guard let run = viewModel.currentRun else { return [] }
        return BlueprintLayoutEngine.computeLayout(for: run.nodes)
    }

    private var canvasSize: CGSize {
        BlueprintLayoutEngine.canvasSize(for: layouts)
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Scrollable canvas
            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical]) {
                    canvasContent
                        .scaleEffect(magnification * steadyStateMagnification)
                        .frame(
                            width: canvasSize.width * magnification * steadyStateMagnification,
                            height: canvasSize.height * magnification * steadyStateMagnification
                        )
                }
                .scrollIndicators(.hidden)
                .onAppear { scrollProxy = proxy }
            }
            .gesture(magnificationGesture)

            // Floating control bar at top
            controlBar
                .padding(.top, 12)
        }
        .overlay(alignment: .trailing) {
            // Floating side panel when a node is selected
            if viewModel.selectedNode != nil {
                nodeDetailPanel
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.selectedNode?.id)
        .onContinuousHover { phase in
            guard !reduceMotion else { return }
            switch phase {
            case .active(let location):
                mouseOffset = CGSize(
                    width: (location.x - 400) * 0.008,
                    height: (location.y - 300) * 0.008
                )
            case .ended:
                withAnimation(.easeOut(duration: 0.5)) {
                    mouseOffset = .zero
                }
            }
        }
        .onChange(of: viewModel.activeNodeIndex) { oldValue, newValue in
            autoScrollToActiveNode()
        }
    }

    // MARK: - Canvas Content

    private var canvasContent: some View {
        ZStack {
            // Layer 1: Background grid with parallax
            gridPattern
                .offset(mouseOffset)

            // Layer 2: Ambient background particles
            AmbientParticlesView()

            // Layer 3: Connections
            if let run = viewModel.currentRun {
                ConnectionsLayerView(layouts: layouts, nodes: run.nodes)
            }

            // Layer 4: Particles
            if let run = viewModel.currentRun {
                ParticleFlowLayerView(
                    layouts: layouts,
                    nodes: run.nodes,
                    simulationSpeed: viewModel.simulationSpeed
                )
            }

            // Layer 5: Nodes
            if let run = viewModel.currentRun {
                ForEach(layouts) { layout in
                    let node = run.nodes.first { $0.id == layout.id }
                    BlueprintNodeView(
                        layout: layout,
                        status: node?.status ?? .pending,
                        duration: node?.duration ?? 0,
                        isSelected: viewModel.selectedNode?.id == layout.id,
                        onTap: {
                            withAnimation(.spring(duration: 0.3)) {
                                viewModel.selectNode(id: layout.id)
                            }
                        }
                    )
                    .id("node-\(layout.id)")
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    // MARK: - Auto-Scroll

    private func autoScrollToActiveNode() {
        guard !reduceMotion else { return }
        guard let run = viewModel.currentRun else { return }
        let idx = viewModel.activeNodeIndex
        guard idx < run.nodes.count else { return }
        let nodeId = run.nodes[idx].id

        withAnimation(.spring(duration: 0.6)) {
            scrollProxy?.scrollTo("node-\(nodeId)", anchor: .center)
        }
    }

    // MARK: - Grid Pattern

    private var gridPattern: some View {
        Canvas { context, size in
            let gridSpacing: CGFloat = 24
            let dotRadius: CGFloat = 1.0
            let dotColor = colorScheme == .dark
                ? Color.white.opacity(0.06)
                : Color.black.opacity(0.06)

            for x in stride(from: CGFloat(0), through: size.width, by: gridSpacing) {
                for y in stride(from: CGFloat(0), through: size.height, by: gridSpacing) {
                    let rect = CGRect(
                        x: x - dotRadius,
                        y: y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Magnification Gesture

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let delta = value.magnification / (magnification != 0 ? magnification : 1)
                magnification = value.magnification
                _ = delta
            }
            .onEnded { value in
                steadyStateMagnification = clampZoom(steadyStateMagnification * value.magnification)
                magnification = 1.0
            }
    }

    private func clampZoom(_ zoom: CGFloat) -> CGFloat {
        min(max(zoom, 0.4), 3.0)
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack(spacing: 16) {
            // Play/Pause
            Button {
                if viewModel.isSimulating {
                    viewModel.pauseSimulation()
                } else {
                    viewModel.startSimulation()
                }
            } label: {
                Image(systemName: viewModel.isSimulating ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundColor(DesignTokens.accent)

            // Step Forward
            Button {
                viewModel.stepForward()
            } label: {
                Image(systemName: "forward.frame.fill")
                    .font(.system(size: 14))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundColor(DesignTokens.textPrimary(for: colorScheme))
            .disabled(viewModel.isSimulating)

            // Reset
            Button {
                viewModel.resetSimulation()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundColor(DesignTokens.textPrimary(for: colorScheme))

            Divider()
                .frame(height: 20)

            // Speed slider
            HStack(spacing: 6) {
                Text("Speed")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.textSecondary)

                Slider(value: Bindable(viewModel).simulationSpeed, in: 1.0...5.0, step: 0.5)
                    .frame(width: 100)

                Text(String(format: "%.1fx", viewModel.simulationSpeed))
                    .font(DesignTokens.Typography.codeSmall)
                    .foregroundColor(DesignTokens.textSecondary)
                    .frame(width: 32, alignment: .trailing)
            }

            Divider()
                .frame(height: 20)

            // Current node label
            currentNodeLabel
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
    }

    private var currentNodeLabel: some View {
        Group {
            if let run = viewModel.currentRun {
                let total = run.nodes.count
                let completed = viewModel.completedNodeCount + viewModel.failedNodeCount
                let activeIdx = viewModel.activeNodeIndex
                let currentName = activeIdx < total ? run.nodes[activeIdx].name : "Complete"

                HStack(spacing: 6) {
                    Text(currentName)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.textPrimary(for: colorScheme))
                        .lineLimit(1)

                    Text("\(completed)/\(total)")
                        .font(DesignTokens.Typography.codeSmall)
                        .foregroundColor(DesignTokens.textSecondary)
                }
            }
        }
    }

    // MARK: - Node Detail Panel

    private var nodeDetailPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let node = viewModel.selectedNode {
                // Header with close button
                HStack {
                    Text(node.name)
                        .font(DesignTokens.Typography.subheading)
                        .foregroundColor(DesignTokens.textPrimary(for: colorScheme))
                        .lineLimit(2)

                    Spacer()

                    Button {
                        viewModel.selectedNode = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(DesignTokens.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                // Node type
                HStack(spacing: 8) {
                    Text("Type")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.textSecondary)
                    Spacer()
                    Text(node.nodeType.rawValue.capitalized)
                        .font(DesignTokens.Typography.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            node.nodeType == .agentic
                                ? DesignTokens.accent.opacity(0.15)
                                : DesignTokens.running.opacity(0.15)
                        )
                        .clipShape(Capsule())
                        .foregroundColor(
                            node.nodeType == .agentic
                                ? DesignTokens.accent
                                : DesignTokens.running
                        )
                }

                // Status
                HStack(spacing: 8) {
                    Text("Status")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.textSecondary)
                    Spacer()
                    statusPill(for: node.status)
                }

                // Duration
                HStack(spacing: 8) {
                    Text("Duration")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.textSecondary)
                    Spacer()
                    Text(formattedDuration(node.duration))
                        .font(DesignTokens.Typography.code)
                        .foregroundColor(DesignTokens.textPrimary(for: colorScheme))
                }

                // Retry count (for CI fix nodes)
                if node.retryCount > 0 {
                    HStack(spacing: 8) {
                        Text("Retries")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.textSecondary)
                        Spacer()
                        Text("\(node.retryCount)")
                            .font(DesignTokens.Typography.code)
                            .foregroundColor(DesignTokens.warning)
                    }
                }

                // Output log
                if !node.output.isEmpty {
                    Divider()

                    Text("Output")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.textSecondary)

                    ScrollView {
                        Text(node.output)
                            .font(DesignTokens.Typography.code)
                            .foregroundColor(DesignTokens.textPrimary(for: colorScheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 200)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark
                                ? Color.black.opacity(0.3)
                                : Color.black.opacity(0.05))
                    )
                }
            }
        }
        .padding(16)
        .frame(width: 280)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 12, x: -2, y: 0)
        )
        .padding(.trailing, 12)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func statusPill(for status: NodeStatus) -> some View {
        let (color, text): (Color, String) = {
            switch status {
            case .pending: return (DesignTokens.pending, "Pending")
            case .running: return (DesignTokens.running, "Running")
            case .completed: return (DesignTokens.success, "Completed")
            case .failed: return (DesignTokens.failure, "Failed")
            case .skipped: return (DesignTokens.pending, "Skipped")
            }
        }()

        Text(text)
            .font(DesignTokens.Typography.caption)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        if duration <= 0 { return "-" }
        if duration < 1 {
            return String(format: "%.0fms", duration * 1000)
        } else if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
}

// MARK: - Ambient Background Particles

struct AmbientParticlesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct AmbientDot {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: CGFloat
        let speed: CGFloat
        let phase: CGFloat
    }

    private let dots: [AmbientDot] = {
        var result: [AmbientDot] = []
        // Use a fixed seed pattern for consistency
        let count = 30
        for i in 0..<count {
            let fi = CGFloat(i)
            result.append(AmbientDot(
                x: ((fi * 137.508).truncatingRemainder(dividingBy: 1.0) + fi * 0.01).truncatingRemainder(dividingBy: 1.0),
                y: ((fi * 97.31).truncatingRemainder(dividingBy: 1.0) + fi * 0.007).truncatingRemainder(dividingBy: 1.0),
                size: 1.5 + (fi * 23.7).truncatingRemainder(dividingBy: 2.0),
                opacity: 0.04 + (fi * 17.3).truncatingRemainder(dividingBy: 0.06),
                speed: 0.3 + (fi * 11.9).truncatingRemainder(dividingBy: 0.5),
                phase: (fi * 47.1).truncatingRemainder(dividingBy: .pi * 2)
            ))
        }
        return result
    }()

    var body: some View {
        if !reduceMotion {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    let baseColor = colorScheme == .dark
                        ? Color.white
                        : Color(red: 0.39, green: 0.4, blue: 0.95)

                    for dot in dots {
                        let x = dot.x * size.width + sin(now * dot.speed + dot.phase) * 15
                        let y = dot.y * size.height + cos(now * dot.speed * 0.7 + dot.phase) * 10
                        let pulseFactor = 0.7 + 0.3 * sin(now * dot.speed * 1.5 + dot.phase)

                        let rect = CGRect(
                            x: x - dot.size / 2,
                            y: y - dot.size / 2,
                            width: dot.size,
                            height: dot.size
                        )

                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(baseColor.opacity(dot.opacity * pulseFactor))
                        )
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }
}
