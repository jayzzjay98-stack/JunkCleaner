import SwiftUI

struct ScanProgressSection: View {
    let scanner: JunkScanner
    @State private var shimmerOffset: CGFloat = -1.0

    var body: some View {
        if scanner.isScanning {
            VStack(spacing: 9) {
                // Label
                HStack {
                    Text(scanner.currentScanTask)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(DS.textSecondary)
                        .lineLimit(1)
                        .animation(.easeInOut, value: scanner.currentScanTask)
                    Spacer()
                    Text(String(format: "%.0f%%", scanner.scanProgress * 100))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(DS.textTertiary)
                }

                // Track
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DS.bgQuaternary)
                            .frame(height: 4)

                        // Filled portion
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DS.gradientScanBar)
                            .frame(
                                width: max(0, geo.size.width * scanner.scanProgress),
                                height: 4
                            )
                            .animation(.easeInOut(duration: 0.3), value: scanner.scanProgress)
                            .overlay(
                                // Shimmer overlay
                                GeometryReader { fillGeo in
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .clear,
                                                    .white.opacity(0.35),
                                                    .clear
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: fillGeo.size.width * 0.4)
                                        .offset(x: fillGeo.size.width * shimmerOffset)
                                        .onAppear {
                                            withAnimation(
                                                .linear(duration: 1.4).repeatForever(autoreverses: false)
                                            ) {
                                                shimmerOffset = 1.4
                                            }
                                        }
                                }
                                .clipped()
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        // Glowing dot at tip
                        let tipX = max(4, geo.size.width * scanner.scanProgress)
                        Circle()
                            .fill(DS.lavender)
                            .frame(width: 10, height: 10)
                            .shadow(color: DS.lavender.opacity(0.9), radius: 5)
                            .offset(x: tipX - 5, y: -3)
                            .animation(.easeInOut(duration: 0.3), value: scanner.scanProgress)
                    }
                }
                .frame(height: 10)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 16)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}
