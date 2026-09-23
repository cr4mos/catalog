//
//  CatalogSnapshot.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation

struct CatalogSnapshot: Equatable, Sendable {
    let products: [Product]
    let savedAt: Date
}
