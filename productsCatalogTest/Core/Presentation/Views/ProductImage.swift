//
//  ProductImage.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import SwiftUI

struct ProductImage: View {
    let url: URL?
    var pointSize: CGFloat = 80
    @Environment(\.displayScale) private var displayScale
    @Environment(\.imageLoader) private var imageLoader
    @State private var viewModel = ProductImageViewModel()
    @State private var retry = 0

    var body: some View {
        ZStack {
            DS.Palette.subtle
            if let loadedImage = viewModel.image {
                Image(decorative: loadedImage, scale: displayScale)
                    .resizable()
                    .scaledToFit()
                    .padding(DS.Space.xs)
            } else if viewModel.failed {
                Button {
                    retry += 1
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(minWidth: DS.Size.touchTarget, minHeight: DS.Size.touchTarget)
                }
                .accessibilityLabel("Reintentar imagen")
                .buttonStyle(.borderless)
            } else if url != nil {
                ProgressView()
            } else {
                Image(systemName: "shippingbox")
                    .font(.title)
                    .foregroundStyle(DS.Palette.muted)
                    .accessibilityHidden(true)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
        .task(id: "\(url?.absoluteString ?? "")-\(displayScale)-\(pointSize)-\(retry)") {
            await viewModel.load(url: url, maxPixels: Int(pointSize * displayScale), loader: imageLoader)
        }
    }
}
