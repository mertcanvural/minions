import SwiftUI

// MARK: - Connection View

struct ConnectionView: View {
    let connection: NodeConnection
    let fromStatus: NodeStatus
    let toStatus: NodeStatus

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawProgress: CGFloat = 0

    var body: some View {
        let path = BlueprintLayoutEngine.connectionPath(for: connection)

        ZStack {
            // Background dashed path (always visible for pending)
            if isPending {
                path.stroke(
                    strokeColor,
                    style: strokeStyle
                )
                .opacity(connectionOpacity)
            }

            // Shadow/glow layer for active connections
            if isActive {
                path.stroke(
                    strokeColor.opacity(0.3),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .blur(radius: 4)
                .opacity(Double(drawProgress))
            }

            // Main connection stroke with trim animation
            if !isPending {
                path.trim(from: 0, to: drawProgress)
                    .stroke(
                        strokeColor,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .opacity(connectionOpacity)
            }

            // Arrow at endpoint (only visible when fully drawn)
            if drawProgress >= 1.0 {
                arrowHead
            }
        }
        .onChange(of: fromStatus) { _, newStatus in
            if newStatus == .completed || newStatus == .failed {
                if reduceMotion {
                    drawProgress = 1.0
                } else {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        drawProgress = 1.0
                    }
                }
            }
        }
        .onAppear {
            drawProgress = shouldBeDrawn ? 1.0 : 0.0
        }
    }

    // MARK: - Arrow Head

    private var arrowHead: some View {
        let endPoint = connection.toPoint
        let arrowSize: CGFloat = 6

        // Get direction at the endpoint by sampling near the end
        let nearEnd = BlueprintLayoutEngine.pointAlongConnection(connection, at: 0.95)
        let angle = atan2(endPoint.y - nearEnd.y, endPoint.x - nearEnd.x)

        return Path { path in
            path.move(to: endPoint)
            path.addLine(to: CGPoint(
                x: endPoint.x - arrowSize * cos(angle - .pi / 6),
                y: endPoint.y - arrowSize * sin(angle - .pi / 6)
            ))
            path.move(to: endPoint)
            path.addLine(to: CGPoint(
                x: endPoint.x - arrowSize * cos(angle + .pi / 6),
                y: endPoint.y - arrowSize * sin(angle + .pi / 6)
            ))
        }
        .stroke(strokeColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        .opacity(connectionOpacity)
    }

    // MARK: - Computed Properties

    private var isActive: Bool {
        fromStatus == .completed || fromStatus == .running
    }

    private var shouldBeDrawn: Bool {
        fromStatus == .completed || fromStatus == .failed || fromStatus == .running
    }

    private var strokeColor: Color {
        if connection.isFailurePath {
            if fromStatus == .failed {
                return DesignTokens.failure
            }
            return DesignTokens.failure.opacity(0.4)
        }

        switch fromStatus {
        case .completed:
            return DesignTokens.success
        case .running:
            return DesignTokens.running
        case .failed:
            return DesignTokens.failure
        default:
            return DesignTokens.pending.opacity(0.4)
        }
    }

    private var strokeStyle: StrokeStyle {
        if isPending {
            return StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 4])
        }
        return StrokeStyle(lineWidth: 2, lineCap: .round)
    }

    private var isPending: Bool {
        fromStatus == .pending || fromStatus == .skipped
    }

    private var connectionOpacity: Double {
        switch fromStatus {
        case .skipped: return 0.2
        case .pending: return 0.4
        default: return 1.0
        }
    }
}

// MARK: - Connections Layer

struct ConnectionsLayerView: View {
    let layouts: [NodeLayout]
    let nodes: [BlueprintNode]

    var body: some View {
        ForEach(layouts) { layout in
            ForEach(layout.connections) { connection in
                let toNode = nodes.first { $0.id == connection.targetNodeId }
                let fromNode = nodes.first { $0.id == layout.id }

                ConnectionView(
                    connection: connection,
                    fromStatus: fromNode?.status ?? .pending,
                    toStatus: toNode?.status ?? .pending
                )
            }
        }
    }
}
