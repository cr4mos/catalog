//
//  ProductDetailView.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import SwiftUI

struct ProductDetailView: View {
    let product: Product
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                ProductImage(url: product.images.first ?? product.thumbnail, pointSize: 480)
                    .frame(height: 240)
                    .accessibilityLabel("Imagen de \(product.title)")

                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    DSBadge(
                        title: product.category.replacingOccurrences(of: "-", with: " ").capitalized,
                        tone: .sky)
                    Text(product.title).font(DS.TypeStyle.title)
                        .accessibilityAddTraits(.isHeader)
                    if let brand = product.brand {
                        Text(brand).font(DS.TypeStyle.detail).foregroundStyle(DS.Palette.muted)
                    }
                    Text(product.formattedPrice).font(DS.TypeStyle.price)
                    Text("Precios en MXN").font(DS.TypeStyle.caption).foregroundStyle(DS.Palette.muted)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: DS.Space.sm) { facts }
                    VStack(alignment: .leading, spacing: DS.Space.sm) { facts }
                }
                DSCard {
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Acerca del producto").font(DS.TypeStyle.section)
                            .accessibilityAddTraits(.isHeader)
                        Text(product.description).font(DS.TypeStyle.body).textSelection(.enabled)
                            .foregroundStyle(DS.Palette.muted)
                    }
                }
            }
            .padding(DS.Space.lg)
            .frame(maxWidth: DS.Size.readableWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(DS.Palette.canvas)
        .foregroundStyle(DS.Palette.ink)
        .accessibilityIdentifier("productDetail")
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: onToggleFavorite) {
                Label(
                    isFavorite ? "Guardado en favoritos" : "Guardar en favoritos",
                    systemImage: isFavorite ? "heart.fill" : "heart"
                )
            }
            .buttonStyle(DSButtonStyle(kind: isFavorite ? .primary : .accent))
            .accessibilityIdentifier("detailFavorite")
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.sm)
            .frame(maxWidth: DS.Size.readableWidth)
            .frame(maxWidth: .infinity)
            .background(DS.Palette.canvas)
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var facts: some View {
        DSMetric(
            title: "Calificación",
            value: product.rating.formatted(.number.precision(.fractionLength(1))) + " / 5",
            systemImage: "star", tone: .sky
        )
        .accessibilityLabel("Calificación: \(product.rating.formatted()) de 5")
        DSMetric(
            title: "Disponibilidad",
            value: product.stock > 0 ? "\(product.stock) disponibles" : "Sin existencias",
            systemImage: "shippingbox", tone: product.stock > 0 ? .mint : .peach)
    }
}
