import SwiftUI
import AppKit

// MARK: - Window Configuration
struct WindowConfiguration {
    static let minWidth: CGFloat = 1200
    static let minHeight: CGFloat = 800
    static let idealWidth: CGFloat = 1400
    static let idealHeight: CGFloat = 900
    static let maxWidth: CGFloat = .infinity
    static let maxHeight: CGFloat = .infinity
    
    // Modal Window Sizes
    static let modalMinWidth: CGFloat = 800
    static let modalMinHeight: CGFloat = 600
    static let modalIdealWidth: CGFloat = 900
    static let modalIdealHeight: CGFloat = 700
    
    // Sidebar Sizes
    static let sidebarMinWidth: CGFloat = 260
    static let sidebarIdealWidth: CGFloat = 280
    static let sidebarMaxWidth: CGFloat = 320
    static let sidebarCollapsedWidth: CGFloat = 80
    
    // Detail View Sizes
    static let detailMinWidth: CGFloat = 900
    static let detailIdealWidth: CGFloat = 1200
}

// MARK: - Window Manager
class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    @Published var isCompact = false
    @Published var currentWindowSize = CGSize(width: WindowConfiguration.idealWidth, height: WindowConfiguration.idealHeight)
    
    private init() {
        setupWindowObserver()
    }
    
    private func setupWindowObserver() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let window = notification.object as? NSWindow {
                self?.handleWindowResize(window.frame.size)
            }
        }
    }
    
    private func handleWindowResize(_ size: CGSize) {
        currentWindowSize = size
        isCompact = size.width < WindowConfiguration.detailMinWidth
    }
    
    func configureMainWindow(_ window: NSWindow) {
        window.minSize = CGSize(width: WindowConfiguration.minWidth, height: WindowConfiguration.minHeight)
        window.setContentSize(CGSize(width: WindowConfiguration.idealWidth, height: WindowConfiguration.idealHeight))
        window.center()
        
        // Set window style
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.styleMask.insert(.fullSizeContentView)
    }
    
    func configureModalWindow(_ window: NSWindow) {
        window.minSize = CGSize(width: WindowConfiguration.modalMinWidth, height: WindowConfiguration.modalMinHeight)
        window.setContentSize(CGSize(width: WindowConfiguration.modalIdealWidth, height: WindowConfiguration.modalIdealHeight))
        window.center()
        
        // Modal window specific settings
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
    }
}

// MARK: - Responsive View Modifier
struct ResponsiveModifier: ViewModifier {
    @ObservedObject private var windowManager = WindowManager.shared
    
    func body(content: Content) -> some View {
        content
            .environment(\.isCompact, windowManager.isCompact)
            .environment(\.currentWindowSize, windowManager.currentWindowSize)
    }
}

// MARK: - Environment Values
private struct IsCompactKey: EnvironmentKey {
    static let defaultValue = false
}

private struct CurrentWindowSizeKey: EnvironmentKey {
    static let defaultValue = CGSize(width: WindowConfiguration.idealWidth, height: WindowConfiguration.idealHeight)
}

extension EnvironmentValues {
    var isCompact: Bool {
        get { self[IsCompactKey.self] }
        set { self[IsCompactKey.self] = newValue }
    }
    
    var currentWindowSize: CGSize {
        get { self[CurrentWindowSizeKey.self] }
        set { self[CurrentWindowSizeKey.self] = newValue }
    }
}

// MARK: - View Extensions
extension View {
    func responsive() -> some View {
        modifier(ResponsiveModifier())
    }
    
    func adaptiveSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            content()
                .frame(
                    minWidth: WindowConfiguration.modalMinWidth,
                    idealWidth: WindowConfiguration.modalIdealWidth,
                    minHeight: WindowConfiguration.modalMinHeight,
                    idealHeight: WindowConfiguration.modalIdealHeight
                )
        }
    }
    
    func adaptivePopover<Content: View>(
        isPresented: Binding<Bool>,
        attachmentAnchor: PopoverAttachmentAnchor = .point(.topTrailing),
        arrowEdge: Edge = .top,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.popover(
            isPresented: isPresented,
            attachmentAnchor: attachmentAnchor,
            arrowEdge: arrowEdge
        ) {
            content()
                .frame(minWidth: 300, maxWidth: 400)
                .padding()
        }
    }
}

// MARK: - Adaptive Layout Components
struct AdaptiveHStack<Content: View>: View {
    @Environment(\.isCompact) private var isCompact
    
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    let content: Content
    
    init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        if isCompact {
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
        } else {
            HStack(alignment: alignment, spacing: spacing) {
                content
            }
        }
    }
}

struct AdaptiveGrid<Content: View>: View {
    @Environment(\.currentWindowSize) private var windowSize
    
    let minItemWidth: CGFloat
    let spacing: CGFloat
    let content: Content
    
    init(
        minItemWidth: CGFloat = 300,
        spacing: CGFloat = AppTheme.Spacing.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.minItemWidth = minItemWidth
        self.spacing = spacing
        self.content = content()
    }
    
    private var columns: Int {
        let availableWidth = windowSize.width - (AppTheme.Spacing.xl * 2) // Account for padding
        let columnCount = max(1, Int(availableWidth / (minItemWidth + spacing)))
        return min(columnCount, 4) // Maximum 4 columns
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            content
        }
    }
}

// MARK: - Adaptive Typography
struct AdaptiveText: View {
    let text: String
    let style: AppTheme.Typography.TextStyle
    
    @Environment(\.isCompact) private var isCompact
    
    enum TextStyle {
        case largeTitle, title1, title2, title3, headline, body, caption
        
        func font(isCompact: Bool) -> Font {
            if isCompact {
                switch self {
                case .largeTitle: return AppTheme.Typography.largeTitle
                case .title1: return .title
                case .title2: return .title2
                case .title3: return .title3
                case .headline: return .headline
                case .body: return .body
                case .caption: return .caption
                }
            } else {
                switch self {
                case .largeTitle: return AppTheme.Typography.largeTitle
                case .title1: return .title
                case .title2: return .title2
                case .title3: return .title3
                case .headline: return .headline
                case .body: return .body
                case .caption: return .caption
                }
            }
        }
    }
    
    init(_ text: String, style: AppTheme.Typography.TextStyle = .body) {
        self.text = text
        self.style = style
    }
    
    var body: some View {
        Text(text)
            .font(style.resolveFont(isCompact: isCompact))
    }
}

// MARK: - App Theme Typography Extension
extension AppTheme.Typography {
    enum TextStyle {
        case largeTitle, title1, title2, title3, headline, body, caption
    }
}
// MARK: - Typography TextStyle Font Resolution
extension AppTheme.Typography.TextStyle {
    func resolveFont(isCompact: Bool) -> Font {
        switch self {
        case .largeTitle:
            return .largeTitle
        case .title1:
            return .title
        case .title2:
            return .title2
        case .title3:
            return .title3
        case .headline:
            return .headline
        case .body:
            return .body
        case .caption:
            return .caption
        }
    }
}
