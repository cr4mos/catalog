//
//  DesignSystemGallery.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

#if DEBUG
    import SwiftUI

    /// Interactive component catalog; contains no network or production dependencies.
    struct DesignSystemGallery: View {
        @State private var query = ""
        @State private var favoritesOnly = false

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Space.lg) {
                        DSFeatureCard(
                            eyebrow: "CATÁLOGO · DESIGN SYSTEM", title: "Simple. Cercano. Tuyo.",
                            message: "Una base editorial con controles nativos de iOS.", systemImage: "sparkles")
                        DSCard {
                            VStack(alignment: .leading, spacing: DS.Space.md) {
                                Text("Tipografía y superficies").font(DS.TypeStyle.section)
                                Text("Un diseño que deja respirar al contenido.").font(DS.TypeStyle.body)
                                Text("Detalles y texto de apoyo").font(DS.TypeStyle.caption)
                                    .foregroundStyle(DS.Palette.muted)
                            }
                        }
                        ViewThatFits(in: .horizontal) {
                            HStack { badges }
                            VStack(alignment: .leading) { badges }
                        }
                        Button("Acción principal") {}.buttonStyle(DSButtonStyle())
                        Button("Acción destacada") {}.buttonStyle(DSButtonStyle(kind: .accent))
                        Button("Acción secundaria") {}.buttonStyle(DSButtonStyle(kind: .secondary))
                        Button("No disponible") {}.buttonStyle(DSButtonStyle()).disabled(true)
                        DSCard {
                            VStack(spacing: DS.Space.md) {
                                TextField("Buscar productos", text: $query).textFieldStyle(.roundedBorder)
                                Toggle("Solo favoritos", isOn: $favoritesOnly)
                                ProgressView("Actualizando catálogo")
                            }
                        }
                    }
                    .padding(DS.Space.lg)
                    .frame(maxWidth: DS.Size.readableWidth)
                    .frame(maxWidth: .infinity)
                }
                .background(DS.Palette.canvas)
                .foregroundStyle(DS.Palette.ink)
                .navigationTitle("Componentes")
                .navigationBarTitleDisplayMode(.inline)
                .tint(DS.Palette.ink)
            }
        }

        @ViewBuilder private var badges: some View {
            DSBadge(title: "Disponible", systemImage: "checkmark", tone: .mint)
            DSBadge(title: "Categoría", tone: .sky)
            DSBadge(title: "Sin existencias", tone: .peach)
        }
    }

    #Preview("Sistema · claro") { DesignSystemGallery().preferredColorScheme(.light) }
    #Preview("Sistema · oscuro") { DesignSystemGallery().preferredColorScheme(.dark) }
    #Preview("Sistema · accesibilidad") { DesignSystemGallery().dynamicTypeSize(.accessibility3) }
#endif
