//
//  ItemSelectorSheet.swift
//  Pokedex
//
//  Created on 2025-11-02.
//

import SwiftUI

/// ダメージ計算用のアイテム選択シート
struct ItemSelectorSheet: View {
    let items: [ItemEntity]
    let onSelect: (ItemEntity?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                if filteredItems.isEmpty {
                    Text(String(localized: "damage_calc.item_not_found"))
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        // 「なし」選択肢
                        Button(action: {
                            onSelect(nil)
                            dismiss()
                        }) {
                            HStack {
                                Text(String(localized: "damage_calc.none"))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)

                        // アイテムリスト
                        ForEach(filteredItems) { item in
                            Button(action: {
                                onSelect(item)
                                dismiss()
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.nameJa)
                                        .font(.body)
                                        .fontWeight(.medium)

                                    Text(item.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    // 効果説明（あれば）
                                    if let descriptionJa = item.descriptionJa {
                                        Text(descriptionJa)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "damage_calc.select_item"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: String(localized: "damage_calc.search_item"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }

    /// 検索フィルタリングされたアイテムリスト
    private var filteredItems: [ItemEntity] {
        if searchText.isEmpty {
            return items
        }

        return items.filter { item in
            // 名前で検索（日本語・英語）
            if item.nameJa.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            if item.name.localizedCaseInsensitiveContains(searchText) {
                return true
            }

            // 説明文で検索
            if let descriptionJa = item.descriptionJa,
               descriptionJa.localizedCaseInsensitiveContains(searchText) {
                return true
            }

            return false
        }
    }
}
