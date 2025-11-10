//
//  PartyPokemonSelectorSheet.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Pokemon selector for adding to party
//
//  Created by Claude on 2025-11-09.
//

import SwiftUI
import Kingfisher

struct PartyPokemonSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PokemonListViewModel
    let onSelect: (Pokemon) -> Void

    init(onSelect: @escaping (Pokemon) -> Void) {
        self.onSelect = onSelect
        _viewModel = StateObject(wrappedValue: DIContainer.shared.makePokemonListViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.filteredPokemons) { pokemonWithMatch in
                    Button {
                        onSelect(pokemonWithMatch.pokemon)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            // Pokemon sprite
                            if let imageURL = pokemonWithMatch.pokemon.displayImageURL {
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

                            // Pokemon name
                            VStack(alignment: .leading, spacing: 2) {
                                // 図鑑番号と名前
                                HStack(spacing: 8) {
                                    Text(pokemonWithMatch.pokemon.formattedId)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(pokemonWithMatch.pokemon.displayName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                }

                                // タイプバッジ
                                HStack(spacing: 4) {
                                    ForEach(pokemonWithMatch.pokemon.types) { type in
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
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(NSLocalizedString("party.select_pokemon", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "")) {
                        dismiss()
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: NSLocalizedString("party.search_pokemon", comment: ""))
            .task {
                await viewModel.loadPokemons()
            }
        }
    }
}
