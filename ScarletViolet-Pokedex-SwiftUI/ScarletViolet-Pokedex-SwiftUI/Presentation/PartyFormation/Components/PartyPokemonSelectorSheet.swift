//
//  PartyPokemonSelectorSheet.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Pokemon selector for adding to party
//
//  Created by Claude on 2025-11-09.
//

import SwiftUI

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
                            // Pokemon number
                            Text("#\(pokemonWithMatch.pokemon.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .leading)

                            // Pokemon name
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pokemonWithMatch.pokemon.displayName)
                                    .font(.body)

                                // Types
                                HStack(spacing: 4) {
                                    ForEach(pokemonWithMatch.pokemon.types, id: \.name) { type in
                                        Text(type.displayName)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.gray.opacity(0.2))
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
            .navigationTitle("Select Pokémon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search Pokémon")
            .task {
                await viewModel.loadPokemons()
            }
        }
    }
}
