import SwiftUI

struct AuditLogPopoutView: View {
    var body: some View {
        NavigationStack {
            AuditLogView()
        }
    }
}

#Preview {
    AuditLogPopoutView()
        .environment(AppState())
}
