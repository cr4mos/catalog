//
//  Product+Formatting.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation

extension Product {
    var formattedPrice: String {
        price.formatted(.currency(code: "MXN").locale(Locale(identifier: "es_MX")))
    }
}
