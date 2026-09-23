import SwiftUI

@main struct MyApp: App {
    @State private var viewModel = AppEnvironment.makeViewModel()
    var body: some Scene {
        WindowGroup {
            Group {
                CatalogView(viewModel: viewModel)
            }
            .tint(DS.Palette.ink)
            .foregroundColor(DS.Palette.ink)
            .environment(\.imageLoader, ImageLoader.shared)
            .environment(\.locale, Locale(identifier: "es_MX"))
        }

    }
}
