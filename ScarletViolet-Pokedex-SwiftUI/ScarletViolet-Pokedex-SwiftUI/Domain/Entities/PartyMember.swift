//
//  PartyMember.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Created by Claude on 2025-11-09.
//

import Foundation

/// パーティメンバー（個別ポケモンの設定）
///
/// パーティに登録されたポケモン1匹分の詳細設定を保持します。
struct PartyMember: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let pokemonId: Int
    var nickname: String?
    var formId: Int?  // リージョンフォームなどのフォームID
    var selectedMoves: [SelectedMove]  // 最大4
    var ability: String
    var item: String?
    var nature: Nature
    var evs: StatValues  // 努力値
    var ivs: StatValues  // 個体値
    var level: Int  // 1-100
    var teraType: String  // テラスタイプ（19種類から選択）
    var position: Int  // パーティ内の位置（0-5）

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        pokemonId: Int,
        nickname: String? = nil,
        formId: Int? = nil,
        selectedMoves: [SelectedMove] = [],
        ability: String,
        item: String? = nil,
        nature: Nature = .hardy,
        evs: StatValues = .zero,
        ivs: StatValues = .maxIVs,
        level: Int = 50,
        teraType: String = "normal",
        position: Int = 0
    ) {
        self.id = id
        self.pokemonId = pokemonId
        self.nickname = nickname
        self.formId = formId
        self.selectedMoves = selectedMoves
        self.ability = ability
        self.item = item
        self.nature = nature
        self.evs = evs
        self.ivs = ivs
        self.level = level
        self.teraType = teraType
        self.position = position
    }
}

/// 選択された技
///
/// パーティメンバーが覚えている技の情報を保持します。
struct SelectedMove: Codable, Hashable, Sendable {
    let moveName: String
    let moveType: String  // 技のタイプ
    let slot: Int  // 技スロット（0-3）
    let power: Int?
    let accuracy: Int?
    let pp: Int

    init(
        moveName: String,
        moveType: String,
        slot: Int,
        power: Int? = nil,
        accuracy: Int? = nil,
        pp: Int = 0
    ) {
        self.moveName = moveName
        self.moveType = moveType
        self.slot = slot
        self.power = power
        self.accuracy = accuracy
        self.pp = pp
    }
}
