import SwiftUI

struct EmptyState: View {
    let icon: String
    let title: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Layout.paddingM) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text(title).font(.title3)
            if let buttonTitle, let action {
                Button { action() } label: {
                    Label(buttonTitle, systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
