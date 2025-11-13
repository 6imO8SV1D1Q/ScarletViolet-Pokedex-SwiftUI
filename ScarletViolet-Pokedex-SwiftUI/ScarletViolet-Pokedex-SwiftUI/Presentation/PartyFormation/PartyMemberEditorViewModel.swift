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
    @Published var availableItems: [ItemEntity] = []
    @Published var selectedForm: PokemonForm?

    // MARK: - Dependencies

    private let pokemonRepository: PokemonRepositoryProtocol
    private let moveRepository: MoveRepositoryProtocol
    private let itemProvider: ItemProviderProtocol

    // MARK: - Initialization

    init(
        member: PartyMember,
        pokemonRepository: PokemonRepositoryProtocol,
        moveRepository: MoveRepositoryProtocol,
        itemProvider: ItemProviderProtocol
    ) {
        self.member = member
        self.pokemonRepository = pokemonRepository
        self.moveRepository = moveRepository
        self.itemProvider = itemProvider
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
            // Note: loadAvailableItems() is called separately in .task
        } catch {
            // TODO: Error handling
        }
    }

    func loadAvailableItems() async {
        do {
            let allItems = try await itemProvider.fetchAllItems()
            print("📦 [PartyMemberEditor] Loaded \(allItems.count) total items")
            availableItems = allItems
                .filter { $0.category == "held-item" }
                .sorted { $0.id < $1.id }
            print("✅ [PartyMemberEditor] Filtered to \(availableItems.count) held items")
        } catch {
            print("❌ [PartyMemberEditor] Failed to load items: \(error)")
            availableItems = []
        }
    }

    private func loadAvailableMoves(pokemon: Pokemon) async {
        // Extract unique move IDs from pokemon.moves
        let moveIds = pokemon.moves.map { $0.id }
        print("📦 [PartyMemberEditor] Loading \(moveIds.count) moves for \(pokemon.displayName)")

        // Fetch move details
        let moves = await withTaskGroup(of: MoveEntity?.self) { group in
            for moveId in moveIds {
                group.addTask { [moveRepository] in
                    do {
                        let move = try await moveRepository.fetchMoveDetail(moveId: moveId, versionGroup: "scarlet-violet")
                        return move
                    } catch {
                        print("⚠️ [PartyMemberEditor] Failed to load move \(moveId): \(error)")
                        return nil
                    }
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
        print("✅ [PartyMemberEditor] Loaded \(availableMoves.count) moves successfully")
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
