import SwiftUI

struct SidebarView: View {
    @Binding var selectedItem: NavigationItem?
    @AppStorage("compactSidebar") private var compactSidebar = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("GasGrid Manager")
                .font(.system(.headline, design: .rounded))
                .padding(.horizontal, Layout.paddingXL)
                .padding(.vertical, compactSidebar ? Layout.paddingS : Layout.paddingL)

            Divider()

            VStack(spacing: 1) {
                ForEach(NavigationItem.allCases) { item in
                    if item == .settings {
                        Divider().padding(.vertical, 6)
                    }
                    SidebarRow(item: item, isSelected: selectedItem == item)
                        .onTapGesture { selectedItem = item }
                }
            }
            .padding(.vertical, 6)

            Spacer(minLength: 0)

            Divider()
            HStack {
                Circle().fill(.green).frame(width: 6, height: 6)
                Text("System Online")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, Layout.paddingXL)
            .padding(.vertical, 10)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct SidebarRow: View {
    let item: NavigationItem
    let isSelected: Bool
    @State private var isHovered = false
    @AppStorage("enableAnimations") private var enableAnimations = true

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? item.selectedIcon : item.icon)
                .font(.system(size: Layout.iconSizeSmall))
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .frame(width: Layout.iconSizeMedium)
            Text(item.rawValue)
                .font(.body)
                .foregroundStyle(isSelected ? .primary : .secondary)
            Spacer()
        }
        .padding(.horizontal, Layout.paddingXL)
        .padding(.vertical, Layout.paddingS)
        .frame(maxWidth: .infinity, minHeight: 32)
        .contentShape(RoundedRectangle(cornerRadius: Layout.cornerRadiusS))
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadiusS)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : isHovered ? Color.primary.opacity(0.05) : Color.clear)
                .padding(.horizontal, Layout.paddingS)
        )
        .animation(enableAnimations ? .easeInOut(duration: Layout.sidebarAnimationDuration) : nil, value: isHovered)
        .onHover { isHovered = $0 }
    }
}
