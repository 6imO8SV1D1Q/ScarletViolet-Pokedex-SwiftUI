//
//  AnalyzePartyUseCase.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Created by Claude on 2025-11-09.
//

import Foundation

/// パーティのタイプ相性を分析するUseCase
protocol AnalyzePartyUseCaseProtocol: Sendable {
    /// パーティのタイプ相性を分析
    ///
    /// パーティ全体の弱点、耐性、攻撃範囲などを分析します。
    /// テラスタルも考慮した分析を行います。
    ///
    /// - Parameter party: 分析対象のパーティ
    /// - Returns: タイプ相性分析結果
    func execute(_ party: Party) async -> TypeCoverage
}

/// AnalyzePartyUseCaseの実装
final class AnalyzePartyUseCase: AnalyzePartyUseCaseProtocol {
    // TypeRepositoryが必要になる場合は後で追加
    // private let typeRepository: TypeRepositoryProtocol

    init() {
        // 必要に応じてRepositoryを注入
    }

    func execute(_ party: Party) async -> TypeCoverage {
        // TODO: 実際のタイプ相性分析ロジックを実装
        // 現時点では空の結果を返す
        // 後でTypeRepositoryを使用して詳細な分析を実装予定

        // パーティが空の場合
        guard !party.members.isEmpty else {
            return TypeCoverage.empty
        }

        // 仮の実装：メンバー数に基づく簡単なカバレッジスコア
        let coverageScore = Double(party.members.count) / 6.0

        return TypeCoverage(
            weaknesses: [:],
            resistances: [:],
            immunities: [],
            coverageScore: coverageScore
        )
    }
}
