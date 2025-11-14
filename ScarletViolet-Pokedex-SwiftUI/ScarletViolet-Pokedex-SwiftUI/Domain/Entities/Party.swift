//
//  Party.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Created by Claude on 2025-11-09.
//

import Foundation

/// パーティ全体
///
/// 最大6匹のポケモンで構成されるパーティ情報を保持します。
struct Party: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var members: [PartyMember]  // 最大6
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Computed Properties

    /// パーティが満員かどうか
    var isFull: Bool {
        members.count >= 6
    }

    /// パーティの平均レベル
    var averageLevel: Double {
        guard !members.isEmpty else { return 0 }
        let total = members.reduce(0) { $0 + $1.level }
        return Double(total) / Double(members.count)
    }

    /// テラスタイプの分布
    ///
    /// - Returns: テラスタイプごとのポケモン数
    var teraTypeDistribution: [String: Int] {
        var distribution: [String: Int] = [:]
        for member in members {
            distribution[member.teraType, default: 0] += 1
        }
        return distribution
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        members: [PartyMember] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.members = members
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 空のパーティを作成
    static var empty: Party {
        Party(name: "New Party")
    }

    /// パーティ名のデフォルトを生成
    static func defaultName(index: Int) -> String {
        "Party \(index + 1)"
    }
}
