//
//  PartyModel.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  SwiftData persistence model for Party
//
//  Created by Claude on 2025-11-09.
//

import Foundation
import SwiftData

/// SwiftDataモデル: パーティ全体の永続化
@Model
final class PartyModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var members: [PartyMemberModel]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        name: String,
        members: [PartyMemberModel],
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.members = members
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// SwiftDataモデル: パーティメンバー（個別ポケモン）の永続化
@Model
final class PartyMemberModel {
    var id: UUID
    var pokemonId: Int
    var nickname: String?
    var formId: Int?
    var selectedMovesData: Data  // JSON encoded [SelectedMove]
    var ability: String
    var item: String?
    var nature: String
    var evsData: Data  // JSON encoded StatValues
    var ivsData: Data  // JSON encoded StatValues
    var level: Int
    var teraType: String
    var position: Int

    init(
        id: UUID,
        pokemonId: Int,
        nickname: String? = nil,
        formId: Int? = nil,
        selectedMovesData: Data,
        ability: String,
        item: String? = nil,
        nature: String,
        evsData: Data,
        ivsData: Data,
        level: Int,
        teraType: String,
        position: Int
    ) {
        self.id = id
        self.pokemonId = pokemonId
        self.nickname = nickname
        self.formId = formId
        self.selectedMovesData = selectedMovesData
        self.ability = ability
        self.item = item
        self.nature = nature
        self.evsData = evsData
        self.ivsData = ivsData
        self.level = level
        self.teraType = teraType
        self.position = position
    }
}
