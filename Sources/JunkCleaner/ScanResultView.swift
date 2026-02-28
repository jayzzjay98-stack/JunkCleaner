import SwiftUI

struct ScanResultView: View {
    @Binding var results: ScanResult
    @Binding var cleaningInProgress: Bool
    var cleanAction: () -> Void

    var body: some View {
        VStack {
            List(results.items) { item in
                HStack {
                    Image(systemName: item.type.icon)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading) {
                        Text(item.displayName)
                            .font(.headline)
                        Text(item.path)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text(item.formattedSize)
                        .font(.body.monospacedDigit())
                }
            }
            .listStyle(.plain)
            
            Button(action: cleanAction) {
                if cleaningInProgress {
                    ProgressView()
                } else {
                    Text("Clean Selected (\(results.items.filter { $0.isSelected }.count) items)")
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .disabled(cleaningInProgress || results.items.isEmpty)
        }
    }
}
