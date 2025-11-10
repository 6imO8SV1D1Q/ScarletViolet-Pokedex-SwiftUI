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
                // TODO: Load available moves from pokemon.moves
            }
        } catch {
            // TODO: Error handling
        }
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
