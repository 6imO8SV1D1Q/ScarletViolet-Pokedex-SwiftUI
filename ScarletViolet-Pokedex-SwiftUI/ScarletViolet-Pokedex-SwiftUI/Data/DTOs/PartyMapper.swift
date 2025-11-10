//
//  PartyMapper.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Mapper for converting between Party domain entity and PartyModel data model
//
//  Created by Claude on 2025-11-09.
//

import Foundation

/// PartyとPartyModel間の変換を行うMapper
enum PartyMapper {
    /// SwiftDataモデルからDomainエンティティに変換
    ///
    /// - Parameter model: SwiftDataのPartyModel
    /// - Returns: DomainのPartyエンティティ
    static func toDomain(_ model: PartyModel) -> Party {
        Party(
            id: model.id,
            name: model.name,
            members: model.members.map { PartyMemberMapper.toDomain($0) },
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }

    /// DomainエンティティからSwiftDataモデルに変換
    ///
    /// - Parameter domain: DomainのPartyエンティティ
    /// - Returns: SwiftDataのPartyModel
    static func toModel(_ domain: Party) -> PartyModel {
        PartyModel(
            id: domain.id,
            name: domain.name,
            members: domain.members.map { PartyMemberMapper.toModel($0) },
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }
}
