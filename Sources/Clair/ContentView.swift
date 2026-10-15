import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var cleaner: CleanerViewModel
    @State private var showConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if cleaner.isScanning {
                Spacer()
                ProgressView("Analyse de votre espace de stockage…")
                Spacer()
            } else if cleaner.items.isEmpty {
                ContentUnavailableView("Prêt à analyser", systemImage: "sparkles",
                    description: Text("Clair recherche les caches, journaux et installateurs pouvant être retirés sans supprimer vos documents."))
            } else {
                List {
                    ForEach(groupedCategories, id: \.self) { category in
                        Section {
                            ForEach(cleaner.items.filter { $0.category == category }) { item in
                                HStack(spacing: 12) {
                                    Toggle("", isOn: Binding(get: { item.selected }, set: { _ in cleaner.toggle(item) }))
                                        .labelsHidden()
                                    Image(systemName: icon(for: category)).foregroundStyle(.secondary)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.id.lastPathComponent).lineLimit(1)
                                        Text(item.id.path).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                    Spacer()
                                    Text(item.displaySize).monospacedDigit().foregroundStyle(.secondary)
                                }
                                .help(item.explanation)
                            }
                        } header: {
                            HStack {
                                Text(category)
                                Spacer()
                                Button("Tout sélectionner") { cleaner.selectCategory(category, selected: true) }
                                    .buttonStyle(.link)
                            }
                        }
                    }
                }
            }
            Divider()
            HStack {
                Text("(cleaner.selectedCount) élément(s) · (ByteCountFormatter.string(fromByteCount: cleaner.selectedSize, countStyle: .file)) sélectionné(s)")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Déplacer vers la Corbeille", role: .destructive) { showConfirmation = true }
                    .disabled(cleaner.selectedCount == 0)
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) { Button("Analyser", systemImage: "arrow.clockwise") { cleaner.scan() }.disabled(cleaner.isScanning) }
        }
        .alert("Déplacer les éléments sélectionnés ?", isPresented: $showConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Déplacer vers la Corbeille", role: .destructive) { cleaner.moveSelectedToTrash() }
        } message: { Text("Les fichiers restent récupérables dans la Corbeille jusqu’à ce que vous la vidiez.") }
        .alert("Clair", isPresented: Binding(get: { cleaner.completionMessage != nil }, set: { if !$0 { cleaner.dismissMessage() } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(cleaner.completionMessage ?? "") }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("Clair", systemImage: "broom.fill").font(.largeTitle.bold())
            Text("Un nettoyage transparent : vous choisissez toujours ce qui part, et tout est envoyé à la Corbeille.")
                .foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
    }

    private var groupedCategories: [String] { Array(Set(cleaner.items.map(\.category))).sorted() }
    private func icon(for category: String) -> String { category == "Corbeille" ? "trash" : category == "Installateurs anciens" ? "shippingbox" : "doc.text" }
}
