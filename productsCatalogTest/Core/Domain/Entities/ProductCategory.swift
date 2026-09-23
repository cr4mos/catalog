import Foundation

enum ProductCategory {
    static let spanishNames: [String: String] = [
        "beauty": "Belleza",
        "fragrances": "Perfumes",
        "furniture": "Muebles",
        "groceries": "Alimentos",
        "home-decoration": "Decoración del hogar",
        "kitchen-accessories": "Accesorios de cocina",
        "laptops": "Computadoras portátiles",
        "mens-shirts": "Camisas para hombre",
        "mens-shoes": "Calzado para hombre",
        "mens-watches": "Relojes para hombre",
        "mobile-accessories": "Accesorios para celular",
        "motorcycle": "Motocicletas",
        "skin-care": "Cuidado de la piel",
        "smartphones": "Teléfonos celulares",
        "sports-accessories": "Accesorios deportivos",
        "sunglasses": "Lentes de sol",
        "tablets": "Tabletas",
        "tops": "Blusas",
        "vehicle": "Vehículos",
        "womens-bags": "Bolsas para mujer",
        "womens-dresses": "Vestidos para mujer",
        "womens-jewellery": "Joyería para mujer",
        "womens-shoes": "Calzado para mujer",
        "womens-watches": "Relojes para mujer"
    ]

    static func name(for category: String) -> String {
        spanishNames[category] ?? "Otros productos"
    }
}

extension Product {
    var categoryName: String { ProductCategory.name(for: category) }
}
