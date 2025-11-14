//
//  SavePartyUseCase.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Created by Claude on 2025-11-09.
//

import Foundation

/// パーティを保存するUseCase
protocol SavePartyUseCaseProtocol: Sendable {
    /// パーティを保存
    ///
    /// 更新日時を自動的に更新してから保存します。
    ///
    /// - Parameter party: 保存するパーティ
    /// - Throws: データ保存時のエラー
    func execute(_ party: Party) async throws
}

/// SavePartyUseCaseの実装
final class SavePartyUseCase: SavePartyUseCaseProtocol {
    private let repository: PartyRepositoryProtocol

    init(repository: PartyRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ party: Party) async throws {
        var updatedParty = party
        updatedParty.updatedAt = Date()
        try await repository.saveParty(updatedParty)
    }
}
