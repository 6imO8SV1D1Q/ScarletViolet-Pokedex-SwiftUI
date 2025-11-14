//
//  DeletePartyUseCase.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Created by Claude on 2025-11-09.
//

import Foundation

/// パーティを削除するUseCase
protocol DeletePartyUseCaseProtocol: Sendable {
    /// パーティを削除
    ///
    /// - Parameter id: 削除するパーティのID
    /// - Throws: データ削除時のエラー
    func execute(id: UUID) async throws
}

/// DeletePartyUseCaseの実装
final class DeletePartyUseCase: DeletePartyUseCaseProtocol {
    private let repository: PartyRepositoryProtocol

    init(repository: PartyRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: UUID) async throws {
        try await repository.deleteParty(id: id)
    }
}
