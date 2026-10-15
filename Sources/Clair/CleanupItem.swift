import Foundation

struct CleanupItem: Identifiable, Hashable {
    let id: URL
    let category: String
    let explanation: String
    let size: Int64
    let modifiedAt: Date?
    var selected: Bool

    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

enum CleanupCategory: CaseIterable {
    case userCaches, logs, trash, oldDownloads

    var name: String {
        switch self {
        case .userCaches: "Caches utilisateur"
        case .logs: "Journaux anciens"
        case .trash: "Corbeille"
        case .oldDownloads: "Installateurs anciens"
        }
    }

    var explanation: String {
        switch self {
        case .userCaches: "Données temporaires recréées par les applications."
        case .logs: "Fichiers de diagnostic âgés de plus de 30 jours."
        case .trash: "Éléments déjà placés dans la Corbeille."
        case .oldDownloads: "Images disque et installateurs âgés de plus de 30 jours."
        }
    }
}
