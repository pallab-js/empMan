import SwiftUI

// MARK: - Thread-Safe Cached Color from Hex
private let colorLock = NSLock()
private var colorCache: [String: Color] = [:]

extension Color {
    init(hex: String) {
        let key = hex
        colorLock.lock()
        if let cached = colorCache[key] {
            colorLock.unlock()
            self = cached
            return
        }
        colorLock.unlock()

        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        let color = Color(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)

        colorLock.lock()
        colorCache[key] = color
        colorLock.unlock()

        self = color
    }
}

// MARK: - Unified Card Style
struct CardModifier: ViewModifier {
    let isHovered: Bool
    let cornerRadius: CGFloat
    let restingShadowOpacity: Double
    let restingShadowRadius: CGFloat
    let restingShadowY: CGFloat
    let hoveredShadowOpacity: Double
    let hoveredShadowRadius: CGFloat
    let hoveredShadowY: CGFloat
    let scaleOnHover: CGFloat

    init(
        isHovered: Bool = false,
        cornerRadius: CGFloat = Layout.cornerRadiusL,
        restingShadowOpacity: Double = 0.04,
        restingShadowRadius: CGFloat = 3,
        restingShadowY: CGFloat = 1,
        hoveredShadowOpacity: Double = 0.1,
        hoveredShadowRadius: CGFloat = 8,
        hoveredShadowY: CGFloat = 4,
        scaleOnHover: CGFloat = 1.01
    ) {
        self.isHovered = isHovered
        self.cornerRadius = cornerRadius
        self.restingShadowOpacity = restingShadowOpacity
        self.restingShadowRadius = restingShadowRadius
        self.restingShadowY = restingShadowY
        self.hoveredShadowOpacity = hoveredShadowOpacity
        self.hoveredShadowRadius = hoveredShadowRadius
        self.hoveredShadowY = hoveredShadowY
        self.scaleOnHover = scaleOnHover
    }

    func body(content: Content) -> some View {
        content
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: .black.opacity(isHovered ? hoveredShadowOpacity : restingShadowOpacity),
                radius: isHovered ? hoveredShadowRadius : restingShadowRadius,
                y: isHovered ? hoveredShadowY : restingShadowY
            )
            .scaleEffect(isHovered ? scaleOnHover : 1.0)
            .animation(AppPreferences.animationsEnabled ? .easeInOut(duration: Layout.animationDuration) : nil, value: isHovered)
    }
}

extension View {
    func cardStyle(
        isHovered: Bool = false,
        cornerRadius: CGFloat = Layout.cornerRadiusL
    ) -> some View {
        modifier(CardModifier(isHovered: isHovered, cornerRadius: cornerRadius))
    }
}

// MARK: - Styled TextEditor
struct StyledTextEditor: View {
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 80

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .padding(4)
        }
        .frame(minHeight: minHeight)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadiusS))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadiusS)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Sheet Header
struct SheetHeader: View {
    var title: String
    var showDestructive: Bool = false
    var destructiveTitle: String = "Delete"
    var onDestructive: (() -> Void)? = nil
    var primaryTitle: String = "Save"
    var primaryDisabled: Bool = false
    var onDismiss: () -> Void = {}
    var onPrimary: () -> Void = {}

    var body: some View {
        HStack {
            Text(title).font(.title2.bold())
            Spacer()
            Button("Cancel") { onDismiss() }.buttonStyle(.bordered)
            if showDestructive, let onDestructive {
                Button(destructiveTitle, role: .destructive) { onDestructive() }
                    .buttonStyle(.bordered)
            }
            Button(primaryTitle) { onPrimary() }
                .buttonStyle(.borderedProminent)
                .disabled(primaryDisabled)
        }
        .padding(Layout.paddingXXL)
        Divider()
    }
}
