import SwiftUI

struct BlueprintPopoutView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        BlueprintView()
    }
}

#Preview {
    BlueprintPopoutView()
        .environment(AppState())
}
