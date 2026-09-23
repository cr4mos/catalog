//
//  DesignTokens.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//
import SwiftUI

enum DS {
    enum Palette {
        static let canvas = Color("DSCanvas")
        static let surface = Color("DSSurface")
        static let subtle = Color("DSSubtle")
        static let ink = Color("DSInk")
        static let muted = Color("DSMuted")
        static let border = Color("DSBorder")
        static let accent = Color("DSAccent")
        static let onAccent = Color("DSOnAccent")
        static let mint = Color("DSMint")
        static let sky = Color("DSSky")
        static let peach = Color("DSPeach")
        
        static let banner = Color("DSBanner")
        static let onBanner = Color("DSOnBanner")
    }
    
    enum Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    enum Radius {
        static let small: CGFloat = 12
        static let card: CGFloat = 20
    }
    
    enum TypeStyle {
        static let title = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let section = Font.system(.title3, design: .rounded).weight(.bold)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .rounded)
        static let detail = Font.system(.subheadline, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let price = Font.system(.title, design: .rounded).weight(.bold)
    }
    
    enum Size {
        static let touchTarget: CGFloat = 48
        static let readableWidth: CGFloat = 680
    }
}
