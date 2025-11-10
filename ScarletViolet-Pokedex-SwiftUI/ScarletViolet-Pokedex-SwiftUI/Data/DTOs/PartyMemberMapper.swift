//
//  PartyMemberMapper.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Mapper for converting between PartyMember domain entity and PartyMemberModel data model
//
//  Created by Claude on 2025-11-09.
//

import Foundation

/// PartyMemberとPartyMemberModel間の変換を行うMapper
enum PartyMemberMapper {
    /// SwiftDataモデルからDomainエンティティに変換
    ///
    /// - Parameter model: SwiftDataのPartyMemberModel
    /// - Returns: DomainのPartyMemberエンティティ
    static func toDomain(_ model: PartyMemberModel) -> PartyMember {
        // JSON decoding with fallback to defaults
        let moves = (try? JSONDecoder().decode([SelectedMove].self, from: model.selectedMovesData)) ?? []
        let evs = (try? JSONDecoder().decode(StatValues.self, from: model.evsData)) ?? .zero
        let ivs = (try? JSONDecoder().decode(StatValues.self, from: model.ivsData)) ?? .maxIVs
        let nature = Nature(rawValue: model.nature) ?? .hardy

        return PartyMember(
            id: model.id,
            pokemonId: model.pokemonId,
            nickname: model.nickname,
            formId: model.formId,
            selectedMoves: moves,
            ability: model.ability,
            item: model.item,
            nature: nature,
            evs: evs,
            ivs: ivs,
            level: model.level,
            teraType: model.teraType,
            position: model.position
        )
    }

    /// DomainエンティティからSwiftDataモデルに変換
    ///
    /// - Parameter domain: DomainのPartyMemberエンティティ
    /// - Returns: SwiftDataのPartyMemberModel
    static func toModel(_ domain: PartyMember) -> PartyMemberModel {
        // JSON encoding with fallback to empty Data
        let movesData = (try? JSONEncoder().encode(domain.selectedMoves)) ?? Data()
        let evsData = (try? JSONEncoder().encode(domain.evs)) ?? Data()
        let ivsData = (try? JSONEncoder().encode(domain.ivs)) ?? Data()

        return PartyMemberModel(
            id: domain.id,
            pokemonId: domain.pokemonId,
            nickname: domain.nickname,
            formId: domain.formId,
            selectedMovesData: movesData,
            ability: domain.ability,
            item: domain.item,
            nature: domain.nature.rawValue,
            evsData: evsData,
            ivsData: ivsData,
            level: domain.level,
            teraType: domain.teraType,
            position: domain.position
        )
    }
}
