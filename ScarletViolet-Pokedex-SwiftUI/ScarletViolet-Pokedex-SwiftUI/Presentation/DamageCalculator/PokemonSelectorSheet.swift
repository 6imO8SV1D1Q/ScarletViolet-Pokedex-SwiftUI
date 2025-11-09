//
//  PokemonSelectorSheet.swift
//  Pokedex
//
//  Created on 2025-11-02.
//

import SwiftUI
import Kingfisher

/// ダメージ計算用のポケモン選択シート
struct PokemonSelectorSheet: View {
    let pokemons: [Pokemon]
    let onSelect: (Pokemon) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                if filteredPokemons.isEmpty {
                    Text(String(localized: "damage_calc.pokemon_not_found"))
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(filteredPokemons) { pokemon in
                        Button(action: {
                            onSelect(pokemon)
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                // スプライト画像
                                if let imageURL = pokemon.displayImageURL {
                                    KFImage(URL(string: imageURL))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    // 図鑑番号と名前
                                    HStack(spacing: 8) {
                                        Text(pokemon.formattedId)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(pokemon.displayName)
                                            .font(.body)
                                            .fontWeight(.medium)
                                    }

                                    // タイプバッジ
                                    HStack(spacing: 4) {
                                        ForEach(pokemon.types) { type in
                                            Text(type.nameJa ?? type.japaneseName)
                                                .font(.caption2)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(type.color)
                                                .foregroundColor(type.textColor)
                                                .cornerRadius(4)
                                        }
                                    }
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(String(localized: "damage_calc.select_pokemon"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: String(localized: "damage_calc.search_pokemon"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }

    /// 検索フィルタリングされたポケモンリスト
    private var filteredPokemons: [Pokemon] {
        if searchText.isEmpty {
            return pokemons
        }

        return pokemons.filter { pokemon in
            // 名前で検索（日本語・英語）
            if let nameJa = pokemon.nameJa, nameJa.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            if pokemon.name.localizedCaseInsensitiveContains(searchText) {
                return true
            }

            // 図鑑番号で検索
            if let nationalDexNumber = pokemon.nationalDexNumber,
               String(nationalDexNumber).contains(searchText) {
                return true
            }
            if String(pokemon.id).contains(searchText) {
                return true
            }

            return false
        }
    }
}
