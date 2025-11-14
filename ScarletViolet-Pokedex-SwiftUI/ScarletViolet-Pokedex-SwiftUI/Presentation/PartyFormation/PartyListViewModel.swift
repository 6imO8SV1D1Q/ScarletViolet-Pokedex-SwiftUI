//
//  PartyListViewModel.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  ViewModel for Party List screen
//
//  Created by Claude on 2025-11-09.
//

import Foundation
import Combine

@MainActor
final class PartyListViewModel: ObservableObject {
    // MARK: - Published State

    @Published var parties: [Party] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingDeleteConfirmation: Bool = false
    @Published var partyToDelete: Party?

    // MARK: - Dependencies

    private let fetchPartiesUseCase: FetchPartiesUseCaseProtocol
    private let deletePartyUseCase: DeletePartyUseCaseProtocol

    // MARK: - Initialization

    init(
        fetchPartiesUseCase: FetchPartiesUseCaseProtocol,
        deletePartyUseCase: DeletePartyUseCaseProtocol
    ) {
        self.fetchPartiesUseCase = fetchPartiesUseCase
        self.deletePartyUseCase = deletePartyUseCase
    }

    // MARK: - Actions

    func loadParties() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            parties = try await fetchPartiesUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteParty(_ party: Party) async {
        do {
            try await deletePartyUseCase.execute(id: party.id)
            await loadParties()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmDelete(_ party: Party) {
        partyToDelete = party
        showingDeleteConfirmation = true
    }
}
