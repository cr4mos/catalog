//
//  CatalogView.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import SwiftUI

struct CatalogView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var selectedID: Product.ID?

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                Picker("Mostrar productos", selection: $viewModel.favoritesOnly) {
                    Text("Todos").tag(false)
                    Text("Favoritos").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DS.Space.md)
                .padding(.vertical, DS.Space.sm)
                content
            }
            .background(DS.Palette.canvas)
            .navigationTitle("Descubre")
            .searchable(text: $viewModel.query, prompt: "Producto, marca o categoría")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Actualizar catálogo")
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 390, max: 480)
        } detail: {
            if let product = viewModel.product(withID: selectedID) {
                ProductDetailView(
                    product: product,
                    isFavorite: viewModel.favoriteIDs.contains(product.id),
                    onToggleFavorite: { viewModel.toggleFavorite(product) }
                )
            } else {
                ContentUnavailableView(
                    "Un nuevo descubrimiento", systemImage: "bag",
                    description: Text("Selecciona un producto para conocer sus detalles.")
                )
                .background(DS.Palette.canvas)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasSnapshot && viewModel.isLoading {
            VStack(spacing: DS.Space.md) {
                ProgressView()
                Text("Preparando tu catálogo…").foregroundStyle(DS.Palette.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let message = viewModel.errorMessage {
            ContentUnavailableView {
                Label("No pudimos conectar", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Reintentar") { Task { await viewModel.load() } }
                    .buttonStyle(DSButtonStyle())
            }
        } else {
            productList
        }
    }

    private var productList: some View {
        let products = viewModel.visibleProducts
        return List(selection: $selectedID) {
            if viewModel.query.isEmpty && !viewModel.favoritesOnly && !products.isEmpty {
                DSFeatureCard(
                    eyebrow: "HECHO PARA DESCUBRIR", title: "Tu próximo favorito.",
                    message: "Explora, encuentra y guarda lo que va contigo.", systemImage: "bag"
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(
                    EdgeInsets(
                        top: DS.Space.xs, leading: DS.Space.md,
                        bottom: DS.Space.md, trailing: DS.Space.md))
            }
            if let notice = viewModel.notice {
                DSCard(fill: DS.Palette.sky) {
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Label(notice, systemImage: "info.circle")
                            .font(DS.TypeStyle.detail)
                        if let date = viewModel.savedAt {
                            Text("Última actualización: \(date.formatted(date: .abbreviated, time: .shortened))")
                                .font(DS.TypeStyle.caption)
                                .foregroundStyle(DS.Palette.muted)
                        }
                        Button("Reintentar actualización") { Task { await viewModel.load() } }
                            .buttonStyle(DSButtonStyle(kind: .secondary))
                            .disabled(viewModel.isLoading)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .accessibilityIdentifier("cacheNotice")
            }
            Section {
                ForEach(products) { product in
                    HStack(spacing: DS.Space.xs) {
                        NavigationLink(value: product.id) {
                            ProductRow(product: product)
                        }
                        FavoriteButton(
                            isFavorite: viewModel.favoriteIDs.contains(product.id),
                            title: product.title,
                            action: { viewModel.toggleFavorite(product) }
                        )
                    }
                    .modifier(DSCardSurface())
                    .tag(product.id)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(
                        EdgeInsets(
                            top: DS.Space.xs, leading: DS.Space.md,
                            bottom: DS.Space.xs, trailing: DS.Space.md))
                }
            } header: {
                HStack {
                    Text("\(products.count) productos").font(DS.TypeStyle.headline)
                        .foregroundStyle(DS.Palette.ink)
                    Spacer()
                    if viewModel.isLoading { ProgressView().accessibilityLabel("Actualizando") }
                }
            }
            if products.isEmpty {
                ContentUnavailableView(
                    viewModel.query.isEmpty
                        ? (viewModel.favoritesOnly ? "Tus favoritos, aquí" : "Catálogo vacío")
                        : "Sin coincidencias",
                    systemImage: viewModel.favoritesOnly ? "heart" : "magnifyingglass",
                    description: Text(
                        viewModel.query.isEmpty
                            ? (viewModel.favoritesOnly
                                ? "Toca el corazón de un producto para guardarlo."
                                : "Vuelve a actualizar más tarde.")
                            : "Prueba con otro nombre, marca o categoría."
                    )
                )
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DS.Palette.canvas)
        .refreshable { await viewModel.load() }
        .accessibilityIdentifier("catalogList")
    }
}

struct ProductRow: View {
    let product: Product
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            if !dynamicTypeSize.isAccessibilitySize {
                ProductImage(url: product.thumbnail)
                    .frame(width: 76, height: 96)
            }
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(product.category.replacingOccurrences(of: "-", with: " ").capitalized)
                    .font(DS.TypeStyle.caption)
                    .foregroundStyle(DS.Palette.muted)
                Text(product.title).font(DS.TypeStyle.headline)
                    .foregroundStyle(DS.Palette.ink)
                if product.stock <= 0 {
                    DSBadge(title: "Sin existencias", tone: .peach)
                }
                Text(product.formattedPrice + " MXN")
                    .font(DS.TypeStyle.detail.weight(.semibold))
                    .foregroundStyle(DS.Palette.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

struct FavoriteButton: View {
    let isFavorite: Bool
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.body.weight(.semibold))
                .foregroundStyle(isFavorite ? DS.Palette.canvas : DS.Palette.ink)
                .frame(width: DS.Size.touchTarget, height: DS.Size.touchTarget)
                .background(isFavorite ? DS.Palette.ink : DS.Palette.subtle, in: Circle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("\(isFavorite ? "Quitar de" : "Añadir a") favoritos: \(title)")
        .accessibilityValue(isFavorite ? "Guardado" : "No guardado")
    }
}
