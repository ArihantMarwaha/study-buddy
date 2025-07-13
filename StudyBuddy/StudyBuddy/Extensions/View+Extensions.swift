//
//  View+Extensions.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI
import Foundation

extension View {
    func glassEffect(style: GlassStyle = .default) -> some View {
        self.background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    func glassEffectID(_ id: String) -> some View {
        self.id(id)
    }
    
    func glassEffectUnion() -> some View {
        self
    }
}

enum GlassStyle {
    case `default`
    case ultraThin
    case vibrant
}
