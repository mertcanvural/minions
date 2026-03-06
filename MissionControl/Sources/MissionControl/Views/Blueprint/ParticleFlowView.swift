import SwiftUI

// MARK: - Particle Model

struct Particle: Identifiable {
    let id: Int
    let connectionId: String
    var progress: CGFloat      // 0.0–1.0 along path
    let speed: CGFloat         // progress per second
    let isFailurePath: Bool
}

// MARK: - Particle Flow View

struct ParticleFlowView: View {
    let layouts: [NodeLayout]
    let nodes: [BlueprintNode]
    let simulationSpeed: Double

    @State private var animationDate = Date()

    /// All active connections (from completed/running nodes to the next node).
    private var activeConnections: [(connection: NodeConnection, fromNode: BlueprintNode)] {
        var result: [(NodeConnection, BlueprintNode)] = []
        for layout in layouts {
            guard let fromNode = nodes.first(where: { $0.id == layout.id }) else { continue }

            // Only emit particles from completed nodes along the relevant path
            guard fromNode.status == .completed || fromNode.status == .failed else { continue }

            for conn in layout.connections {
                // For failure paths, only show particles if the from-node failed
                if conn.isFailurePath && fromNode.status != .failed { continue }
                // For success paths, only show particles if the from-node completed
                if !conn.isFailurePath && fromNode.status != .completed { continue }

                // Only show particles if the target node is running, completed, or failed
                if let toNode = nodes.first(where: { $0.id == conn.targetNodeId }) {
                    if toNode.status == .pending || toNode.status == .skipped { continue }
                }

                result.append((conn, fromNode))
            }
        }
        return result
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate

                for (connection, _) in activeConnections {
                    let particleCount = 4
                    let isFailure = connection.isFailurePath
                    let baseColor = isFailure ? DesignTokens.failure : DesignTokens.accent

                    for i in 0..<particleCount {
                        // Stagger particles evenly across the path cycle
                        let stagger = CGFloat(i) / CGFloat(particleCount)
                        let cycleSpeed = 0.4 * simulationSpeed
                        let rawProgress = (now * cycleSpeed + Double(stagger)).truncatingRemainder(dividingBy: 1.0)
                        let progress = CGFloat(rawProgress)

                        let point = BlueprintLayoutEngine.pointAlongConnection(connection, at: progress)

                        // Opacity: fade in at start, fade out at end
                        let edgeFade: CGFloat = 0.15
                        let opacity: CGFloat
                        if progress < edgeFade {
                            opacity = progress / edgeFade
                        } else if progress > (1.0 - edgeFade) {
                            opacity = (1.0 - progress) / edgeFade
                        } else {
                            opacity = 1.0
                        }

                        // Draw trail (2 fading copies behind the particle)
                        for trailIndex in (1...2).reversed() {
                            let trailOffset = CGFloat(trailIndex) * 0.03
                            let trailProgress = progress - trailOffset
                            guard trailProgress >= 0 else { continue }

                            let trailPoint = BlueprintLayoutEngine.pointAlongConnection(connection, at: trailProgress)
                            let trailOpacity = opacity * (1.0 - CGFloat(trailIndex) * 0.35)
                            let trailSize: CGFloat = 3.0 - CGFloat(trailIndex) * 0.5

                            let trailRect = CGRect(
                                x: trailPoint.x - trailSize / 2,
                                y: trailPoint.y - trailSize / 2,
                                width: trailSize,
                                height: trailSize
                            )

                            context.fill(
                                Path(ellipseIn: trailRect),
                                with: .color(baseColor.opacity(trailOpacity * 0.6))
                            )
                        }

                        // Draw main particle (3.5pt glowing dot)
                        let particleSize: CGFloat = 3.5
                        let particleRect = CGRect(
                            x: point.x - particleSize / 2,
                            y: point.y - particleSize / 2,
                            width: particleSize,
                            height: particleSize
                        )

                        // Glow layer (larger, more transparent)
                        let glowSize: CGFloat = 8.0
                        let glowRect = CGRect(
                            x: point.x - glowSize / 2,
                            y: point.y - glowSize / 2,
                            width: glowSize,
                            height: glowSize
                        )
                        context.fill(
                            Path(ellipseIn: glowRect),
                            with: .color(baseColor.opacity(opacity * 0.25))
                        )

                        // Core particle
                        context.fill(
                            Path(ellipseIn: particleRect),
                            with: .color(baseColor.opacity(opacity * 0.9))
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Particle Flow Layer

struct ParticleFlowLayerView: View {
    let layouts: [NodeLayout]
    let nodes: [BlueprintNode]
    let simulationSpeed: Double

    var body: some View {
        ParticleFlowView(
            layouts: layouts,
            nodes: nodes,
            simulationSpeed: simulationSpeed
        )
    }
}
