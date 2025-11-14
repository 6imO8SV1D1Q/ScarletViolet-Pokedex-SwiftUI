//
//  PartyRepositoryProtocol.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Created by Claude on 2025-11-09.
//

import Foundation

/// パーティのデータ永続化を担当するリポジトリのプロトコル
///
/// データ層の実装とドメイン層を分離し、依存性の逆転を実現します。
protocol PartyRepositoryProtocol: Sendable {
    /// すべてのパーティを取得
    ///
    /// - Returns: 保存されているすべてのパーティ（更新日時の降順）
    /// - Throws: データ取得時のエラー
    func fetchAllParties() async throws -> [Party]

    /// 特定のパーティを取得
    ///
    /// - Parameter id: パーティのID
    /// - Returns: 指定されたIDのパーティ、存在しない場合はnil
    /// - Throws: データ取得時のエラー
    func fetchParty(id: UUID) async throws -> Party?

    /// パーティを保存（新規作成または更新）
    ///
    /// - Parameter party: 保存するパーティ
    /// - Throws: データ保存時のエラー
    func saveParty(_ party: Party) async throws

    /// パーティを削除
    ///
    /// - Parameter id: 削除するパーティのID
    /// - Throws: データ削除時のエラー
    func deleteParty(id: UUID) async throws

    /// パーティを複製
    ///
    /// - Parameter id: 複製元のパーティID
    /// - Returns: 複製されたパーティ（新しいIDが割り当てられる）
    /// - Throws: データ取得・保存時のエラー
    func duplicateParty(id: UUID) async throws -> Party
}
