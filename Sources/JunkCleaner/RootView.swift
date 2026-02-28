import SwiftUI
import AppKit
import UserNotifications

// MARK: - NSView to configure window once it's ready
struct WindowSetup: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            guard let w = v.window else { return }
            w.standardWindowButton(.closeButton)?.isHidden = true
            w.standardWindowButton(.miniaturizeButton)?.isHidden = true
            w.standardWindowButton(.zoomButton)?.isHidden = true
            w.styleMask.insert(.resizable)
            w.minSize = NSSize(width: 900, height: 650)
            w.isOpaque = false
            w.backgroundColor = .clear
        }
        return v
    }
    func updateNSView(_ v: NSView, context: Context) {
        DispatchQueue.main.async {
            v.window?.standardWindowButton(.closeButton)?.isHidden = true
            v.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
            v.window?.standardWindowButton(.zoomButton)?.isHidden = true
        }
    }
}

// MARK: - Root
struct RootView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @State private var showResult = false
    @State private var resultTimer: Timer?

    var body: some View {
        ZStack {
            // ── neo-gradient background ──────────────────────────────────
            T.bgGradient.ignoresSafeArea()

            // ── decorative orbs (matching HTML exactly) ──────────────────
            GeometryReader { geo in
                // top-left orb: bg-primary/20, blur-[120px]
                Circle()
                    .fill(T.primary.opacity(0.20))
                    .blur(radius: 120)
                    .frame(width: 600, height: 600)
                    .offset(
                        x: -geo.size.width  * 0.10,
                        y: -geo.size.height * 0.20
                    )
                // bottom-right orb: bg-blue-600/10, blur-[100px]
                Circle()
                    .fill(T.blue500.opacity(0.10))
                    .blur(radius: 100)
                    .frame(width: 500, height: 500)
                    .offset(
                        x: geo.size.width  * 0.65,
                        y: geo.size.height * 0.60
                    )
            }
            .allowsHitTesting(false)

            // ── main glass container ────────────────────────────────────
            HStack(spacing: 0) {
                AppSidebar()
                MainContentView(
                    scanner: scanner,
                    cleaner: cleaner,
                    showResult: $showResult
                )
            }
            .background(T.glassBg)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(T.glassBorder, lineWidth: 1)
            )
            .padding(20)

            WindowSetup().frame(width: 0, height: 0)
        }
        .frame(minWidth: 900, minHeight: 650)
        .onChange(of: cleaner.isDeleting) { _, deleting in
            if !deleting, cleaner.lastResult != nil {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { showResult = true }
                resultTimer?.invalidate()
                resultTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { _ in
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.35)) { showResult = false }
                    }
                }
            }
        }
        .onAppear {
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }
}
