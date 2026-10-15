import SwiftUI

@main
struct ClairApp: App {
    @StateObject private var cleaner = CleanerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cleaner)
                .frame(minWidth: 780, minHeight: 540)
        }
        .windowStyle(.titleBar)
    }
}
