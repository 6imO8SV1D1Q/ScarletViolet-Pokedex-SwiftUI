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
    @Published var itemLoadError: String?
    @Published var allItemsCount: Int = 0
    @Published var itemCategories: [String] = []
    @Published var bundleDebugInfo: String = ""

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
        print("🚀 [PartyMemberEditor] Starting loadAvailableItems...")

        // Collect bundle debug info
        var debugInfo = ""
        if let resourcePath = Bundle.main.resourcePath {
            debugInfo += "ResourcePath: \(resourcePath)\n"
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
                debugInfo += "Bundle: \(contents.prefix(5).joined(separator: ", "))\n"

                let preloadedPath = (resourcePath as NSString).appendingPathComponent("PreloadedData")
                if FileManager.default.fileExists(atPath: preloadedPath) {
                    if let preloadedContents = try? FileManager.default.contentsOfDirectory(atPath: preloadedPath) {
                        debugInfo += "PreloadedData: \(preloadedContents.joined(separator: ", "))\n"
                    }
                } else {
                    debugInfo += "PreloadedData: NOT FOUND\n"
                }
            }
        }
        bundleDebugInfo = debugInfo

        do {
            // Load all items and filter for held items
            print("🔄 [PartyMemberEditor] Calling itemProvider.fetchAllItems()...")
            let allItems = try await itemProvider.fetchAllItems()
            print("🔍 [PartyMemberEditor] Loaded \(allItems.count) total items")

            // Store for debugging
            allItemsCount = allItems.count
            itemCategories = Array(Set(allItems.map { $0.category })).sorted()

            availableItems = allItems.filter { $0.category == "held-item" }
            print("✅ [PartyMemberEditor] Filtered to \(availableItems.count) held items")
            itemLoadError = nil
            if availableItems.isEmpty {
                print("⚠️ [PartyMemberEditor] No held items found!")
                print("   Total items: \(allItems.count)")
                print("   Categories found: \(itemCategories)")
                if allItems.count == 0 {
                    itemLoadError = "JSON returned 0 items"
                } else {
                    itemLoadError = "Wrong category: \(itemCategories.joined(separator: ", "))"
                }
            } else {
                print("📦 [PartyMemberEditor] Sample items: \(availableItems.prefix(3).map { $0.nameJa })")
            }
        } catch {
            print("❌ [PartyMemberEditor] Failed to load items: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")
            itemLoadError = "Load failed: \(error.localizedDescription)"
            availableItems = []
            allItemsCount = 0
            itemCategories = []
        }
    }

    private func loadAvailableMoves(pokemon: Pokemon) async {
        // Extract unique move IDs from pokemon.moves
        let moveIds = pokemon.moves.map { $0.id }

        // Fetch move details
        let moves = await withTaskGroup(of: MoveEntity?.self) { group in
            for moveId in moveIds {
                group.addTask { [moveRepository] in
                    try? await moveRepository.fetchMoveDetail(moveId: moveId, versionGroup: "scarlet-violet")
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
