//
//  PartyMemberEditorViewModel.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  ViewModel for Party Member Editor screen
//
//  Created by Claude on 2025-11-09.
//

import Foundation
import Combine

@MainActor
final class PartyMemberEditorViewModel: ObservableObject {
    // MARK: - Published State

    @Published var member: PartyMember
    @Published var pokemon: Pokemon?
    @Published var availableForms: [PokemonForm] = []
    @Published var availableMoves: [MoveEntity] = []
    @Published var selectedForm: PokemonForm?

    // MARK: - Dependencies

    private let pokemonRepository: PokemonRepositoryProtocol
    private let moveRepository: MoveRepositoryProtocol

    // MARK: - Initialization

    init(
        member: PartyMember,
        pokemonRepository: PokemonRepositoryProtocol,
        moveRepository: MoveRepositoryProtocol
    ) {
        self.member = member
        self.pokemonRepository = pokemonRepository
        self.moveRepository = moveRepository
    }

    // MARK: - Actions

    func loadPokemonData() async {
        do {
            pokemon = try await pokemonRepository.fetchPokemonDetail(id: member.pokemonId)
            if let pokemon = pokemon {
                availableForms = try await pokemonRepository.fetchPokemonForms(pokemonId: pokemon.id)
                // Load available moves
                await loadAvailableMoves(pokemon: pokemon)
            }
        } catch {
            // TODO: Error handling
        }
    }

    private func loadAvailableMoves(pokemon: Pokemon) async {
        // Extract unique move names from pokemon.moves
        let moveNames = pokemon.moves.map { $0.name }

        // Fetch move details
        let moves = await withTaskGroup(of: MoveEntity?.self) { group in
            for moveName in moveNames {
                group.addTask { [moveRepository] in
                    try? await moveRepository.fetchMoveByName(moveName)
                }
            }

            var results: [MoveEntity] = []
            for await move in group {
                if let move = move {
                    results.append(move)
                }
            }
            return results
        }

        availableMoves = moves.sorted { $0.nameJa < $1.nameJa }
    }

    func updateTeraType(_ type: String) {
        member.teraType = type
    }

    func updateMove(_ move: SelectedMove, at slot: Int) {
        if slot < member.selectedMoves.count {
            member.selectedMoves[slot] = move
        } else {
            member.selectedMoves.append(move)
        }
    }
}
