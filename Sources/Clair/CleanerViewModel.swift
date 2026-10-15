import Foundation

@MainActor
final class CleanerViewModel: ObservableObject {
    @Published private(set) var items: [CleanupItem] = []
    @Published private(set) var isScanning = false
    @Published var errorMessage: String?
    @Published var completionMessage: String?

    var selectedSize: Int64 {
        items.filter(\.selected).reduce(0) { $0 + $1.size }
    }

    var selectedCount: Int { items.filter(\.selected).count }

    func scan() {
        isScanning = true
        errorMessage = nil
        completionMessage = nil
        Task {
            let scanned = await Task.detached(priority: .userInitiated) { Self.findCandidates() }.value
            self.items = scanned.sorted { $0.size > $1.size }
            self.isScanning = false
        }
    }

    func toggle(_ item: CleanupItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].selected.toggle()
    }

    func selectCategory(_ category: String, selected: Bool) {
        for index in items.indices where items[index].category == category {
            items[index].selected = selected
        }
    }

    func moveSelectedToTrash() {
        let targets = items.filter(\.selected)
        guard !targets.isEmpty else { return }
        var failures: [String] = []
        for item in targets {
            do { try FileManager.default.trashItem(at: item.id, resultingItemURL: nil) }
            catch { failures.append(item.id.lastPathComponent) }
        }
        items.removeAll { $0.selected && !failures.contains($0.id.lastPathComponent) }
        completionMessage = failures.isEmpty
            ? "(targets.count) élément(s) déplacé(s) vers la Corbeille."
            : "Certains éléments n’ont pas pu être déplacés : (failures.joined(separator: ", "))."
    }

    func dismissMessage() {
        completionMessage = nil
    }

    nonisolated private static func findCandidates() -> [CleanupItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        let candidates: [(URL, CleanupCategory, Bool)] = [
            (home.appending(path: "Library/Caches"), .userCaches, false),
            (home.appending(path: "Library/Logs"), .logs, true),
            (home.appending(path: ".Trash"), .trash, false),
            (home.appending(path: "Downloads"), .oldDownloads, true)
        ]

        return candidates.flatMap { root, category, needsAgeCheck in
            guard let children = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            ) else { return [] }
            return children.compactMap { url in
                if category == .oldDownloads {
                    let ext = url.pathExtension.lowercased()
                    guard ["dmg", "pkg", "zip", "app"].contains(ext) else { return nil }
                }
                let metadata = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                if needsAgeCheck, let date = metadata?.contentModificationDate, date > cutoff { return nil }
                let size = directorySize(at: url)
                guard size > 0 else { return nil }
                return CleanupItem(id: url, category: category.name, explanation: category.explanation,
                                   size: size, modifiedAt: metadata?.contentModificationDate, selected: false)
            }
        }
    }

    nonisolated private static func directorySize(at url: URL) -> Int64 {
        var total: Int64 = 0
        let keys: Set<URLResourceKey> = [.fileSizeKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { return 0 }
        for case let file as URL in enumerator {
            guard let values = try? file.resourceValues(forKeys: keys), values.isRegularFile == true else { continue }
            total += Int64(values.fileSize ?? 0)
        }
        if total == 0, let values = try? url.resourceValues(forKeys: [.fileSizeKey]) { total = Int64(values.fileSize ?? 0) }
        return total
    }
}
