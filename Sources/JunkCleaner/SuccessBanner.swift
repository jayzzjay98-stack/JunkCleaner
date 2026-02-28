import SwiftUI

struct SuccessBanner: View {
    let cleaner: JunkCleaner
    @Binding var showResult: Bool

    var body: some View {
        if showResult, let result = cleaner.lastResult {
            HStack(spacing: 11) {
                // Success icon
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(T.ok.opacity(0.14))
                        .frame(width: 30, height: 30)
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(T.ok)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Freed \(result.formattedFreed)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(T.ok)
                        .kerning(-0.2)
                    
                    Text("\(result.deletedCount) files deleted · system is clean")
                        .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(T.txt3)
                }

                Spacer()
                
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { showResult = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(T.txt3)
                        .frame(width: 22, height: 22)
                        .background(T.bgHover, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(T.ok.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(T.ok.opacity(0.18), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 18)
            .padding(.bottom, 2)
            .transition(.move(edge: .top).combined(with: .opacity))
        }

        // Error state (optional, keep simple)
        if let error = cleaner.failedItems.first?.reason, !showResult {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(T.warn)
                    .font(.system(size: 13))
                Text(error)
                    .font(.system(size: 11.5))
                    .foregroundStyle(T.txt2)
                    .lineLimit(2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(T.warn.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(T.warn.opacity(0.18), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 18)
            .padding(.bottom, 10)
        }
    }
}
