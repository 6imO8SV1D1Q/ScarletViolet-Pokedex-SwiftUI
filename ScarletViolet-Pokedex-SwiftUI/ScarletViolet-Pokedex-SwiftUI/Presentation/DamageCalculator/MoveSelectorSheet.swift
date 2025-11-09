//
//  MoveSelectorSheet.swift
//  Pokedex
//
//  Created on 2025-11-02.
//

import SwiftUI

/// ダメージ計算用の技選択シート
struct MoveSelectorSheet: View {
    let moves: [MoveEntity]
    let onSelect: (MoveEntity) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedType: String? = nil
    @State private var selectedDamageClass: String? = nil

    var body: some View {
        NavigationView {
            VStack {
                // フィルター
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // タイプフィルター
                        Menu {
                            Button(String(localized: "common.all")) {
                                selectedType = nil
                            }
                            ForEach(allTypes, id: \.self) { type in
                                Button(typeDisplayName(type)) {
                                    selectedType = type
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedType == nil ? String(localized: "filter.type") : typeDisplayName(selectedType!))
                                Image(systemName: "chevron.down")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedType == nil ? Color.gray.opacity(0.2) : Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        }

                        // 分類フィルター
                        Menu {
                            Button(String(localized: "common.all")) {
                                selectedDamageClass = nil
                            }
                            Button(String(localized: "damage_class.physical")) {
                                selectedDamageClass = "physical"
                            }
                            Button(String(localized: "damage_class.special")) {
                                selectedDamageClass = "special"
                            }
                            Button(String(localized: "damage_class.status")) {
                                selectedDamageClass = "status"
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedDamageClass == nil ? String(localized: "filter.category") : damageClassDisplayName(selectedDamageClass!))
                                Image(systemName: "chevron.down")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedDamageClass == nil ? Color.gray.opacity(0.2) : Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                if filteredMoves.isEmpty {
                    Text(String(localized: "damage_calc.move_not_found"))
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(filteredMoves) { move in
                        Button(action: {
                            onSelect(move)
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    // 技名
                                    Text(move.nameJa)
                                        .font(.body)
                                        .fontWeight(.medium)

                                    // タイプと分類
                                    HStack(spacing: 8) {
                                        // タイプバッジ
                                        Text(move.type.nameJa ?? move.type.japaneseName)
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(move.type.color)
                                            .foregroundColor(move.type.textColor)
                                            .cornerRadius(4)

                                        // 分類
                                        Text(move.categoryDisplayName)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)

                                        // 威力
                                        if let power = move.power {
                                            Text(String(localized: "damage_calc.power_format", defaultValue: "Power: \(power)"))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(String(localized: "damage_calc.select_move"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: String(localized: "damage_calc.search_move"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }

    /// 検索・フィルタリングされた技リスト
    private var filteredMoves: [MoveEntity] {
        var result = moves

        // テキスト検索
        if !searchText.isEmpty {
            result = result.filter { move in
                move.nameJa.localizedCaseInsensitiveContains(searchText) ||
                move.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        // タイプフィルター
        if let selectedType = selectedType {
            result = result.filter { $0.type.name == selectedType }
        }

        // 分類フィルター
        if let selectedDamageClass = selectedDamageClass {
            result = result.filter { $0.damageClass == selectedDamageClass }
        }

        return result
    }

    /// 全タイプ
    private let allTypes = [
        "normal", "fire", "water", "grass", "electric", "ice",
        "fighting", "poison", "ground", "flying", "psychic", "bug",
        "rock", "ghost", "dragon", "dark", "steel", "fairy"
    ]

    /// タイプの表示名
    private func typeDisplayName(_ type: String) -> String {
        let key = "type.\(type.lowercased())"
        return NSLocalizedString(key, value: type.capitalized, comment: "")
    }

    /// 分類の表示名
    private func damageClassDisplayName(_ damageClass: String) -> String {
        let key = "damage_class.\(damageClass)"
        return NSLocalizedString(key, value: damageClass, comment: "")
    }
}
