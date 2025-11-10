//
//  PartyFormationViewModel.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  ViewModel for Party Formation screen
//
//  Created by Claude on 2025-11-09.
//

import Foundation
import Combine

@MainActor
final class PartyFormationViewModel: ObservableObject {
    // MARK: - Published State

    @Published var party: Party
    @Published var isEditing: Bool = false
    @Published var selectedMemberIndex: Int?
    @Published var typeAnalysis: TypeCoverage?
    @Published var errorMessage: String?
    @Published var showingPokemonSelector: Bool = false
    @Published var showingMemberEditor: Bool = false
    @Published var memberPokemons: [Pokemon?] = []

    // MARK: - Dependencies

    private let savePartyUseCase: SavePartyUseCaseProtocol
    private let analyzePartyUseCase: AnalyzePartyUseCaseProtocol
    private let pokemonRepository: PokemonRepositoryProtocol

    // MARK: - Initialization

    init(
        party: Party? = nil,
        savePartyUseCase: SavePartyUseCaseProtocol,
        analyzePartyUseCase: AnalyzePartyUseCaseProtocol,
        pokemonRepository: PokemonRepositoryProtocol
    ) {
        self.party = party ?? Party.empty
        self.savePartyUseCase = savePartyUseCase
        self.analyzePartyUseCase = analyzePartyUseCase
        self.pokemonRepository = pokemonRepository
    }

    // MARK: - Actions

    func addPokemon(_ pokemon: Pokemon, at index: Int) {
        let member = PartyMember(
            pokemonId: pokemon.id,
            ability: pokemon.abilities.first?.name ?? "",
            teraType: pokemon.types.first?.name ?? "normal"
        )

        if index < party.members.count {
            party.members[index] = member
        } else {
            party.members.append(member)
        }

        Task { await analyzeTypeMatchups() }
    }

    func removePokemon(at index: Int) {
        guard index < party.members.count else { return }
        party.members.remove(at: index)
        Task { await analyzeTypeMatchups() }
    }

    func movePokemon(from source: Int, to destination: Int) {
        guard source < party.members.count, destination <= party.members.count else { return }
        let member = party.members.remove(at: source)
        party.members.insert(member, at: destination)

        // Update positions
        for (index, _) in party.members.enumerated() {
            party.members[index].position = index
        }
    }

    func saveParty() async throws {
        party.updatedAt = Date()
        try await savePartyUseCase.execute(party)
    }

    func analyzeTypeMatchups() async {
        typeAnalysis = await analyzePartyUseCase.execute(party)
    }

    func selectMember(at index: Int) {
        selectedMemberIndex = index
        showingMemberEditor = true
    }

    func loadMemberPokemons() async {
        memberPokemons = await withTaskGroup(of: (Int, Pokemon?).self) { group in
            for (index, member) in party.members.enumerated() {
                group.addTask { [pokemonRepository] in
                    let pokemon = try? await pokemonRepository.fetchPokemonDetail(id: member.pokemonId)
                    return (index, pokemon)
                }
            }

            var results: [Int: Pokemon?] = [:]
            for await (index, pokemon) in group {
                results[index] = pokemon
            }

            return (0..<party.members.count).map { results[$0] ?? nil }
        }
    }
}
