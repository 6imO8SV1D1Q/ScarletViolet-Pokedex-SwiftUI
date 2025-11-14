//
//  PartyRepository.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Repository implementation for Party data persistence using SwiftData
//
//  Created by Claude on 2025-11-09.
//

import Foundation
import SwiftData

/// パーティリポジトリの実装
///
/// SwiftDataを使用してパーティの永続化を行います。
final class PartyRepository: PartyRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllParties() async throws -> [Party] {
        let descriptor = FetchDescriptor<PartyModel>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        let models = try modelContext.fetch(descriptor)
        return models.map { PartyMapper.toDomain($0) }
    }

    func fetchParty(id: UUID) async throws -> Party? {
        let predicate = #Predicate<PartyModel> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1

        let models = try modelContext.fetch(descriptor)
        return models.first.map { PartyMapper.toDomain($0) }
    }

    func saveParty(_ party: Party) async throws {
        // 既存のパーティを検索
        let predicate = #Predicate<PartyModel> { $0.id == party.id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1

        if let existingModel = try modelContext.fetch(descriptor).first {
            // 既存のパーティを更新
            existingModel.name = party.name
            existingModel.members = party.members.map { PartyMemberMapper.toModel($0) }
            existingModel.createdAt = party.createdAt
            existingModel.updatedAt = party.updatedAt
        } else {
            // 新規パーティを挿入
            let model = PartyMapper.toModel(party)
            modelContext.insert(model)
        }

        try modelContext.save()
    }

    func deleteParty(id: UUID) async throws {
        let predicate = #Predicate<PartyModel> { $0.id == id }
        try modelContext.delete(model: PartyModel.self, where: predicate)
        try modelContext.save()
    }

    func duplicateParty(id: UUID) async throws -> Party {
        guard let original = try await fetchParty(id: id) else {
            throw PartyRepositoryError.partyNotFound
        }

        // メンバーのIDを再生成
        let newMembers = original.members.map { member in
            PartyMember(
                id: UUID(),
                pokemonId: member.pokemonId,
                nickname: member.nickname,
                selectedMoves: member.selectedMoves,
                ability: member.ability,
                item: member.item,
                nature: member.nature,
                evs: member.evs,
                ivs: member.ivs,
                level: member.level,
                teraType: member.teraType,
                position: member.position
            )
        }

        // 新しいIDで複製
        let duplicated = Party(
            id: UUID(),
            name: "\(original.name) (Copy)",
            members: newMembers,
            createdAt: Date(),
            updatedAt: Date()
        )

        try await saveParty(duplicated)
        return duplicated
    }
}

/// PartyRepositoryのエラー型
enum PartyRepositoryError: Error, LocalizedError {
    case partyNotFound
    case saveFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .partyNotFound:
            return "Party not found"
        case .saveFailed:
            return "Failed to save party"
        case .deleteFailed:
            return "Failed to delete party"
        }
    }
}
