import SwiftUI

struct SuccessBanner: View {
    let cleaner: JunkCleaner
    @Binding var showResult: Bool

    var body: some View {
        if showResult, let result = cleaner.lastResult {
            HStack(spacing: 12) {
                // Check icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DS.successDim)
                        .frame(width: 36, height: 36)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.success)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Freed \(result.formattedFreed)")
                        .font(.system(size: 13, weight: .700))
                        .foregroundStyle(DS.gradientSuccess)
                    Text("\(result.deletedCount) files deleted" +
                         (result.failedCount > 0 ? " · ⚠️ \(result.failedCount) failed" : ""))
                        .font(.system(size: 10.5, weight: .400))
                        .foregroundStyle(DS.textTertiary)
                }

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.2)) { showResult = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DS.textTertiary)
                        .frame(width: 22, height: 22)
                        .background(DS.bgQuaternary, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusBanner)
                    .fill(DS.successDim)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radiusBanner)
                            .strokeBorder(DS.successBorder, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
            .transition(.move(edge: .top).combined(with: .opacity))
        }

        // Error state
        if let error = cleaner.failedItems.first?.reason, !showResult {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(DS.warning)
                    .font(.system(size: 13))
                Text(error)
                    .font(.system(size: 11.5))
                    .foregroundStyle(DS.textSecondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusBanner)
                    .fill(DS.warning.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radiusBanner)
                            .strokeBorder(DS.warning.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }
}
