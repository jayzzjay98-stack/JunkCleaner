import Foundation
import AppKit

@Observable
final class JunkCleaner {

    var isDeleting: Bool = false
    var deleteProgress: Double = 0
    var currentDeleteTask: String = ""
    var deletedItems: [JunkItem] = []
    var failedItems: [(item: JunkItem, reason: String)] = []
    var totalFreedBytes: Int64 = 0
    var lastResult: CleanResult?

    struct CleanResult {
        let freedBytes: Int64
        let deletedCount: Int
        let failedCount: Int
        let duration: TimeInterval
        var freedGB: Double { Double(freedBytes) / 1_073_741_824.0 }
    }

    // MARK: - Main Clean Function
    func clean(items: [JunkItem], requireAuth: Bool = true) async {
        guard !isDeleting else { return }
        
        await MainActor.run {
            self.isDeleting = true
            self.deleteProgress = 0
            self.currentDeleteTask = "Preparing to clean..."
            self.deletedItems = []
            self.failedItems = []
            self.totalFreedBytes = 0
            self.lastResult = nil
        }
        
        let start = Date()
        var successCount = 0
        var failCount = 0
        var totalFreed: Int64 = 0
        
        for (index, item) in items.enumerated() {
            await MainActor.run {
                self.currentDeleteTask = "Cleaning: \(item.displayName)"
                self.deleteProgress = Double(index) / Double(items.count)
            }
            
            do {
                try await deleteItem(item)
                successCount += 1
                totalFreed += item.sizeBytes
                await MainActor.run {
                    self.deletedItems.append(item)
                    self.totalFreedBytes = totalFreed
                }
            } catch {
                failCount += 1
                await MainActor.run {
                    self.failedItems.append((item, error.localizedDescription))
                }
            }
        }
        
        let dur = Date().timeIntervalSince(start)
        
        await MainActor.run {
            self.lastResult = CleanResult(freedBytes: totalFreed, deletedCount: successCount, failedCount: failCount, duration: dur)
            self.isDeleting = false
            self.currentDeleteTask = "Finished!"
        }
    }

    // MARK: - ลบ item เดียว
    private func deleteItem(_ item: JunkItem) async throws {
        let path = item.path
        let url = URL(fileURLWithPath: path)
        let fm = FileManager.default
        
        guard fm.fileExists(atPath: path) else {
            return
        }
        
        // Trash it
        var outURL: NSURL?
        do {
            try fm.trashItem(at: url, resultingItemURL: &outURL)
        } catch {
            // fallback to remove
            try fm.removeItem(at: url)
        }
    }
}
