import SwiftUI

@main struct MyApp: App {
    @State private var viewModel = AppEnvironment.makeViewModel()
    var body: some Scene {
        WindowGroup {
         Text("test")
                .task {
                    await viewModel.load()
                }
        }
    }
}
