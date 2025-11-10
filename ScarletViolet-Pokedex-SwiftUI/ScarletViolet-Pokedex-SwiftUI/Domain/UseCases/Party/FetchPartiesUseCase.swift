//
//  FetchPartiesUseCase.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Created by Claude on 2025-11-09.
//

import Foundation

/// パーティ一覧を取得するUseCase
protocol FetchPartiesUseCaseProtocol: Sendable {
    /// すべてのパーティを取得
    ///
    /// - Returns: 保存されているすべてのパーティ（更新日時の降順）
    /// - Throws: データ取得時のエラー
    func execute() async throws -> [Party]
}

/// FetchPartiesUseCaseの実装
final class FetchPartiesUseCase: FetchPartiesUseCaseProtocol {
    private let repository: PartyRepositoryProtocol

    init(repository: PartyRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [Party] {
        try await repository.fetchAllParties()
    }
}
