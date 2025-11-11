//
//  TeraTypePicker.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Tera Type selector with crystal-like visual design
//
//  Created by Claude on 2025-11-09.
//

import SwiftUI

struct TeraTypePicker: View {
    @Binding var selectedTeraType: String
    let pokemonTypes: [String]  // Pokemon's original types

    var body: some View {
        // Grid of all 19 Tera Types (18 + Stellar)
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 70), spacing: 12)
        ], spacing: 12) {
            ForEach(TeraType.allCases, id: \.self) { type in
                TeraTypeButton(
                    teraType: type,
                    isSelected: selectedTeraType == type.rawValue,
                    isPokemonOriginalType: pokemonTypes.contains(type.rawValue)
                ) {
                    selectedTeraType = type.rawValue
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct TeraTypeButton: View {
    let teraType: TeraType
    let isSelected: Bool
    let isPokemonOriginalType: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(teraType.color.opacity(0.2))
                        .frame(width: 56, height: 56)

                    // Crystal icon
                    Image(systemName: "diamond.fill")
                        .foregroundColor(teraType.color)
                        .font(.title2)

                    // Star marker for original type
                    if isPokemonOriginalType {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                            .offset(x: 18, y: -18)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )

                Text(teraType.nameJa)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct TeraTypeBadge: View {
    let teraType: String
    let size: CGFloat = 24

    private var typeEnum: TeraType? {
        TeraType(rawValue: teraType)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(typeEnum?.color.opacity(0.3) ?? Color.gray.opacity(0.3))
                .frame(width: size, height: size)

            Image(systemName: "diamond.fill")
                .font(.system(size: size * 0.5))
                .foregroundColor(typeEnum?.color ?? .gray)
        }
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(radius: 2)
    }
}
