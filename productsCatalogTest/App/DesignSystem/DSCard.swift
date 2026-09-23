//
//  DSCard.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//


import SwiftUI

struct DSCard<Content: View>: View {
    var fill: Color = DS.Palette.surface
    @ViewBuilder let content: Content
    var body: some View {
        content.modifier(DSCardSurface(fill: fill))
    }
}

/// A modifier keeps native List rows structurally intact for selection and navigation.
struct DSCardSurface: ViewModifier {
    var fill: Color = DS.Palette.surface
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .padding(DS.Space.md)
            .background(fill, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .strokeBorder(DS.Palette.border, lineWidth: contrast == .increased ? 2 : 1)
                    .allowsHitTesting(false)
            }
    }
}

enum DSBadgeTone {
    case neutral, mint, sky, peach

    var fill: Color {
        switch self {
        case .neutral: DS.Palette.subtle
        case .mint: DS.Palette.mint
        case .sky: DS.Palette.sky
        case .peach: DS.Palette.peach
        }
    }
}

struct DSBadge: View {
    let title: String
    var systemImage: String?
    var tone: DSBadgeTone = .neutral

    var body: some View {
        HStack(spacing: DS.Space.xxs) {
            if let systemImage { Image(systemName: systemImage).accessibilityHidden(true) }
            Text(title).fixedSize(horizontal: false, vertical: true)
        }
        .font(DS.TypeStyle.caption.weight(.medium))
        .foregroundStyle(DS.Palette.ink)
        .padding(.horizontal, DS.Space.sm)
        .padding(.vertical, DS.Space.xs)
        .background(tone.fill, in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

struct DSButtonStyle: ButtonStyle {
    enum Kind { case primary, accent, secondary }
    var kind: Kind = .primary
    @Environment(\.isEnabled) private var isEnabled

    private var fill: Color {
        switch kind {
        case .primary: DS.Palette.ink
        case .accent: DS.Palette.accent
        case .secondary: DS.Palette.surface
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary: DS.Palette.canvas
        case .accent: DS.Palette.onAccent
        case .secondary: DS.Palette.ink
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.TypeStyle.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.sm)
            .frame(maxWidth: .infinity, minHeight: DS.Size.touchTarget)
            .foregroundStyle(isEnabled ? foreground : DS.Palette.muted)
            .background(isEnabled ? fill : DS.Palette.subtle, in: Capsule())
            .overlay {
                Capsule().strokeBorder(kind == .secondary ? DS.Palette.border : .clear, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct DSMetric: View {
    let title: String
    let value: String
    let systemImage: String
    var tone: DSBadgeTone = .neutral

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Label(title, systemImage: systemImage)
                .font(DS.TypeStyle.caption)
                .foregroundStyle(DS.Palette.muted)
            Text(value)
                .font(DS.TypeStyle.headline)
                .foregroundStyle(DS.Palette.ink)
        }
        .padding(DS.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.fill, in: RoundedRectangle(cornerRadius: DS.Radius.small))
        .accessibilityElement(children: .combine)
    }
}

struct DSFeatureCard: View {
    let eyebrow: String
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            HStack {
                Text(eyebrow)
                    .font(DS.TypeStyle.caption.weight(.semibold))
                    .tracking(1.5)
                Spacer(minLength: DS.Space.xs)
                Image(systemName: systemImage).font(.title2).accessibilityHidden(true)
            }
            .foregroundStyle(DS.Palette.onBanner)
            Text(title)
                .font(DS.TypeStyle.title)
                .foregroundStyle(DS.Palette.onBanner)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(DS.TypeStyle.detail)
                .foregroundStyle(DS.Palette.onBanner)
        }
        .padding(DS.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Palette.banner, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}
