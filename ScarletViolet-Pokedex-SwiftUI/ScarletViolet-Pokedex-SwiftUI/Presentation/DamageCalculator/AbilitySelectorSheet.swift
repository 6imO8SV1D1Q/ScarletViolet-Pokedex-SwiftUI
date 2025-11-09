//
//  AbilitySelectorSheet.swift
//  Pokedex
//
//  Created on 2025-11-02.
//

import SwiftUI

/// ダメージ計算用の特性選択シート
struct AbilitySelectorSheet: View {
    let abilities: [AbilityEntity]
    let onSelect: (AbilityEntity) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                if filteredAbilities.isEmpty {
                    Text(String(localized: "damage_calc.ability_not_found"))
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(filteredAbilities) { ability in
                        Button(action: {
                            onSelect(ability)
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ability.nameJa)
                                    .font(.body)
                                    .fontWeight(.medium)

                                Text(ability.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(String(localized: "damage_calc.select_ability"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: String(localized: "damage_calc.search_ability"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }

    /// 検索フィルタリングされた特性リスト
    private var filteredAbilities: [AbilityEntity] {
        if searchText.isEmpty {
            return abilities
        }

        return abilities.filter { ability in
            // 名前で検索（日本語・英語）
            if ability.nameJa.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            if ability.name.localizedCaseInsensitiveContains(searchText) {
                return true
            }

            return false
        }
    }
}
