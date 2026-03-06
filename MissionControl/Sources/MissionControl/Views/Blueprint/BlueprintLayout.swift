import SwiftUI

// MARK: - Node Layout

struct NodeLayout: Identifiable {
    let id: String
    let nodeIndex: Int
    let name: String
    let nodeType: NodeType
    var position: CGPoint
    let size: CGSize
    var connections: [NodeConnection]
}

struct NodeConnection: Identifiable {
    let id: String
    let fromPoint: CGPoint
    let toPoint: CGPoint
    let targetNodeId: String
    let isFailurePath: Bool
    let controlPoints: (CGPoint, CGPoint)?
}

// MARK: - Layout Engine

struct BlueprintLayoutEngine {
    // Dimensions
    static let agenticNodeSize = CGSize(width: 200, height: 72)
    static let deterministicNodeSize = CGSize(width: 200, height: 60)

    // Spacing
    static let verticalSpacing: CGFloat = 40
    static let columnSpacing: CGFloat = 260

    // Column X positions (center of node)
    private static let col0X: CGFloat = 120
    private static let col1X: CGFloat = col0X + columnSpacing
    private static let col2X: CGFloat = col0X + columnSpacing * 2

    /// Compute the full layout for the 12-node blueprint graph.
    /// Returns an array of `NodeLayout` with positions and connections.
    static func computeLayout(for nodes: [BlueprintNode]) -> [NodeLayout] {
        guard nodes.count == 12 else { return [] }

        // Define grid placement: (column, row) for each node index (0-based)
        // Row spacing is computed from node height + vertical spacing
        let placements: [(col: CGFloat, row: Int)] = [
            (col0X, 0),   // 0: IMPLEMENT TASK
            (col0X, 1),   // 1: RUN LINTERS
            (col1X, 2),   // 2: FIX LINT ISSUES
            (col0X, 3),   // 3: GIT COMMIT
            (col0X, 4),   // 4: PUSH BRANCH
            (col0X, 5),   // 5: CI ATTEMPT 1
            (col1X, 6),   // 6: FIX CI (attempt 1)
            (col1X, 7),   // 7: CI ATTEMPT 2
            (col2X, 8),   // 8: FIX CI (attempt 2)
            (col2X, 9),   // 9: CI FINAL ATTEMPT
            (col0X, 10),  // 10: CREATE PR
            (col2X, 10),  // 11: HUMAN REVIEW
        ]

        // Connection definitions: (fromIndex, toIndex, isFailurePath)
        let connectionDefs: [(from: Int, to: Int, isFailure: Bool)] = [
            (0, 1, false),   // IMPLEMENT -> RUN LINTERS
            (1, 3, false),   // RUN LINTERS -> GIT COMMIT (success)
            (1, 2, true),    // RUN LINTERS -> FIX LINT (failure)
            (2, 3, false),   // FIX LINT -> GIT COMMIT
            (3, 4, false),   // GIT COMMIT -> PUSH BRANCH
            (4, 5, false),   // PUSH BRANCH -> CI ATTEMPT 1
            (5, 10, false),  // CI ATTEMPT 1 -> CREATE PR (success)
            (5, 6, true),    // CI ATTEMPT 1 -> FIX CI 1 (failure)
            (6, 7, false),   // FIX CI 1 -> CI ATTEMPT 2
            (7, 10, false),  // CI ATTEMPT 2 -> CREATE PR (success)
            (7, 8, true),    // CI ATTEMPT 2 -> FIX CI 2 (failure)
            (8, 9, false),   // FIX CI 2 -> CI FINAL
            (9, 10, false),  // CI FINAL -> CREATE PR (success)
            (9, 11, true),   // CI FINAL -> HUMAN REVIEW (failure)
        ]

        // Calculate Y positions for each row
        func rowY(_ row: Int) -> CGFloat {
            var y: CGFloat = 60 // top padding
            for _ in 0..<row {
                // Use the tallest node height for each row
                let maxHeight = max(agenticNodeSize.height, deterministicNodeSize.height)
                y += maxHeight + verticalSpacing
            }
            return y
        }

        // Build node layouts
        var layouts: [NodeLayout] = []
        for (index, node) in nodes.enumerated() {
            let placement = placements[index]
            let size = node.nodeType == .agentic ? agenticNodeSize : deterministicNodeSize
            let position = CGPoint(x: placement.col, y: rowY(placement.row))

            layouts.append(NodeLayout(
                id: node.id,
                nodeIndex: index,
                name: node.name,
                nodeType: node.nodeType,
                position: position,
                size: size,
                connections: []
            ))
        }

        // Build connections with bezier control points
        for def in connectionDefs {
            let fromLayout = layouts[def.from]
            let toLayout = layouts[def.to]

            let fromSize = fromLayout.size
            let toSize = toLayout.size

            // Connection starts from bottom center of source node
            let fromPoint = CGPoint(
                x: fromLayout.position.x,
                y: fromLayout.position.y + fromSize.height / 2
            )

            // Connection ends at top center of target node
            let toPoint = CGPoint(
                x: toLayout.position.x,
                y: toLayout.position.y - toSize.height / 2
            )

            // Compute bezier control points for curved connections
            let controlPoints = computeControlPoints(
                from: fromPoint,
                to: toPoint,
                isFailure: def.isFailure,
                sameColumn: abs(fromLayout.position.x - toLayout.position.x) < 1
            )

            let connection = NodeConnection(
                id: "\(fromLayout.id)->\(toLayout.id)",
                fromPoint: fromPoint,
                toPoint: toPoint,
                targetNodeId: toLayout.id,
                isFailurePath: def.isFailure,
                controlPoints: controlPoints
            )

            layouts[def.from].connections.append(connection)
        }

        return layouts
    }

    /// Compute control points for bezier curves between nodes.
    private static func computeControlPoints(
        from: CGPoint,
        to: CGPoint,
        isFailure: Bool,
        sameColumn: Bool
    ) -> (CGPoint, CGPoint)? {
        if sameColumn {
            // Straight vertical connection - no control points needed for simple case
            // But use mild S-curve for aesthetics if distance is large
            let dy = to.y - from.y
            if dy > verticalSpacing * 3 {
                let midY = (from.y + to.y) / 2
                return (
                    CGPoint(x: from.x, y: midY),
                    CGPoint(x: to.x, y: midY)
                )
            }
            return nil
        }

        // Cross-column connection: create a smooth curve
        let midY = (from.y + to.y) / 2
        let dx = to.x - from.x

        if isFailure {
            // Failure paths curve outward (right) then down to target
            return (
                CGPoint(x: from.x + dx * 0.1, y: from.y + (midY - from.y) * 0.8),
                CGPoint(x: to.x - dx * 0.1, y: to.y - (to.y - midY) * 0.8)
            )
        } else {
            // Success/rejoin paths curve smoothly
            return (
                CGPoint(x: from.x, y: midY),
                CGPoint(x: to.x, y: midY)
            )
        }
    }

    /// Total canvas size needed to display the full layout.
    static func canvasSize(for layouts: [NodeLayout]) -> CGSize {
        guard !layouts.isEmpty else { return CGSize(width: 800, height: 600) }

        var maxX: CGFloat = 0
        var maxY: CGFloat = 0

        for layout in layouts {
            let right = layout.position.x + layout.size.width / 2
            let bottom = layout.position.y + layout.size.height / 2
            maxX = max(maxX, right)
            maxY = max(maxY, bottom)
        }

        // Add padding
        return CGSize(width: maxX + 80, height: maxY + 80)
    }

    /// Compute the path for a connection (used for drawing and particle animation).
    static func connectionPath(for connection: NodeConnection) -> Path {
        var path = Path()
        path.move(to: connection.fromPoint)

        if let cp = connection.controlPoints {
            path.addCurve(
                to: connection.toPoint,
                control1: cp.0,
                control2: cp.1
            )
        } else {
            path.addLine(to: connection.toPoint)
        }

        return path
    }

    /// Get a point along a connection path at the given progress (0.0–1.0).
    /// Used for particle animation positioning.
    static func pointAlongConnection(_ connection: NodeConnection, at progress: CGFloat) -> CGPoint {
        let t = max(0, min(1, progress))

        if let cp = connection.controlPoints {
            // Cubic bezier interpolation
            return cubicBezierPoint(
                p0: connection.fromPoint,
                p1: cp.0,
                p2: cp.1,
                p3: connection.toPoint,
                t: t
            )
        } else {
            // Linear interpolation
            return CGPoint(
                x: connection.fromPoint.x + (connection.toPoint.x - connection.fromPoint.x) * t,
                y: connection.fromPoint.y + (connection.toPoint.y - connection.fromPoint.y) * t
            )
        }
    }

    /// Cubic bezier interpolation.
    private static func cubicBezierPoint(
        p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat
    ) -> CGPoint {
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        let t2 = t * t
        let t3 = t2 * t

        let x = mt3 * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3 * p3.x
        let y = mt3 * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3 * p3.y

        return CGPoint(x: x, y: y)
    }
}
