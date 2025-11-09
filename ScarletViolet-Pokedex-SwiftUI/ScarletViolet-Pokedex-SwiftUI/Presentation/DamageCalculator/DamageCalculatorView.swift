//
//  DamageCalculatorView.swift
//  Pokedex
//
//  Created on 2025-11-01.
//

import SwiftUI

/// ダメージ計算画面
struct DamageCalculatorView: View {
    @StateObject var store: DamageCalculatorStore
    @State private var showingAttackerPokemonSelector = false
    @State private var showingDefenderPokemonSelector = false
    @State private var showingMoveSelector = false
    @State private var showingAttackerAbilitySelector = false
    @State private var showingDefenderAbilitySelector = false
    @State private var showingAttackerItemSelector = false
    @State private var showingDefenderItemSelector = false
    @State private var isMultiTurnMode = false
    @State private var selectingTurnIndex: Int? = nil // どのターンの技を選択中か

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // プリセット選択セクション
                    presetSection

                    // セクションA: モード切替
                    battleModeSection

                    // セクションB: 攻撃側入力
                    participantSection(
                        title: String(localized: "damage_calc.attacker"),
                        participant: store.battleState.attacker,
                        isAttacker: true
                    )

                    // 技選択セクション
                    moveSelectionSection

                    // 入れ替えボタン
                    swapButton

                    // セクションC: 防御側入力
                    participantSection(
                        title: String(localized: "damage_calc.defender"),
                        participant: store.battleState.defender,
                        isAttacker: false
                    )

                    // セクションD: バトル環境
                    environmentSection

                    // セクションF: 結果表示（Phase 2で実装）
                    resultSection
                }
                .padding()
            }
            .navigationTitle(String(localized: "damage_calc.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "damage_calc.reset")) {
                        store.reset()
                    }
                }
            }
            .sheet(isPresented: $showingAttackerPokemonSelector) {
                PokemonSelectorSheet(
                    pokemons: store.availablePokemons,
                    onSelect: { pokemon in
                        store.selectAttackerPokemon(pokemon)
                    }
                )
            }
            .sheet(isPresented: $showingDefenderPokemonSelector) {
                PokemonSelectorSheet(
                    pokemons: store.availablePokemons,
                    onSelect: { pokemon in
                        store.selectDefenderPokemon(pokemon)
                    }
                )
            }
            .sheet(isPresented: $showingMoveSelector) {
                MoveSelectorSheet(
                    moves: store.availableMoves,
                    onSelect: { move in
                        if let turnIndex = selectingTurnIndex {
                            // 複数ターンモード：指定ターンの技を更新
                            store.updateTurnMove(at: turnIndex, moveId: move.id)
                        } else {
                            // 単一ターンモード：通常の技選択
                            store.selectMove(move)
                        }
                        selectingTurnIndex = nil
                    }
                )
            }
            .sheet(isPresented: $showingAttackerAbilitySelector) {
                AbilitySelectorSheet(
                    abilities: store.availableAbilities,
                    onSelect: { ability in
                        store.selectAttackerAbility(ability)
                    }
                )
            }
            .sheet(isPresented: $showingDefenderAbilitySelector) {
                AbilitySelectorSheet(
                    abilities: store.availableAbilities,
                    onSelect: { ability in
                        store.selectDefenderAbility(ability)
                    }
                )
            }
            .sheet(isPresented: $showingAttackerItemSelector) {
                ItemSelectorSheet(
                    items: store.availableItems,
                    onSelect: { item in
                        store.selectAttackerItem(item)
                    }
                )
            }
            .sheet(isPresented: $showingDefenderItemSelector) {
                ItemSelectorSheet(
                    items: store.availableItems,
                    onSelect: { item in
                        store.selectDefenderItem(item)
                    }
                )
            }
            .task {
                await store.loadPokemons()
                await store.loadMoves()
                await store.loadAbilities()
                await store.loadItems()
            }
            .onChange(of: store.battleState.attacker.pokemonId) { _, _ in
                autoCalculate()
            }
            .onChange(of: store.battleState.defender.pokemonId) { _, _ in
                autoCalculate()
            }
            .onChange(of: store.battleState.selectedMoveId) { _, _ in
                autoCalculate()
            }
            .onChange(of: store.battleState.attacker.level) { _, _ in
                autoCalculate()
            }
            .onChange(of: store.battleState.defender.level) { _, _ in
                autoCalculate()
            }
            .onChange(of: store.battleState.attacker.individualValues) { _, _ in
                autoCalculate()
            }
            .onChange(of: store.battleState.defender.individualValues) { _, _ in
                autoCalculate()
            }
            .onChange(of: store.battleState.attacker.effortValues) { _, _ in
                autoCalculate()
            }
            .onChange(of: store.battleState.defender.effortValues) { _, _ in
                autoCalculate()
            }
            .onChange(of: store.battleState.attacker.nature) { _, _ in
                autoCalculate()
            }
            .onChange(of: store.battleState.defender.nature) { _, _ in
                autoCalculate()
            }
            .onChange(of: store.battleState.attacker.isTerastallized) { _, _ in
                autoCalculate()
            }
            .onChange(of: store.battleState.defender.isTerastallized) { _, _ in
                autoCalculate()
            }
            .onChange(of: store.battleState.turnMoves) { _, _ in
                autoCalculate()
            }
            .onChange(of: isMultiTurnMode) { _, _ in
                autoCalculate()
            }
        }
    }

    /// 自動計算
    private func autoCalculate() {
        guard store.battleState.attacker.pokemonId != nil,
              store.battleState.defender.pokemonId != nil else {
            return
        }

        Task {
            if isMultiTurnMode && !store.battleState.turnMoves.isEmpty {
                // 複数ターンモード
                await store.calculateMultiTurnDamage()
            } else if store.battleState.selectedMoveId != nil {
                // 単一ターンモード
                await store.calculateDamage()
            }
        }
    }

    /// 補正倍率の行を表示（1.0倍は表示しない）
    private func modifierRow(label: String, multiplier: Double) -> some View {
        Group {
            if multiplier != 1.0 {
                HStack {
                    Text(label + ":")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("×\(multiplier, specifier: "%.2f")")
                        .font(.caption)
                        .bold()
                        .foregroundColor(multiplierColor(multiplier))
                }
            }
        }
    }

    /// 補正倍率に応じた色
    private func multiplierColor(_ multiplier: Double) -> Color {
        if multiplier >= 2.0 {
            return .red
        } else if multiplier > 1.0 {
            return .orange
        } else if multiplier < 1.0 {
            return .blue
        } else {
            return .primary
        }
    }

    /// ダメージ範囲バー
    private func damageRangeBar(result: DamageResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(String(localized: "damage_calc.damage_range"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(result.minDamage) ~ \(result.maxDamage)")
                    .font(.headline)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景（最大HP）
                    Rectangle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: geometry.size.width, height: 32)

                    // 最大ダメージ範囲
                    Rectangle()
                        .fill(Color.red.opacity(0.3))
                        .frame(
                            width: min(geometry.size.width, geometry.size.width * CGFloat(result.maxDamage) / CGFloat(result.defenderMaxHP)),
                            height: 32
                        )

                    // 最小ダメージ範囲
                    Rectangle()
                        .fill(Color.red.opacity(0.6))
                        .frame(
                            width: min(geometry.size.width, geometry.size.width * CGFloat(result.minDamage) / CGFloat(result.defenderMaxHP)),
                            height: 32
                        )

                    // テキストオーバーレイ
                    HStack {
                        Text("HP: \(result.defenderMaxHP)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.leading, 4)
                        Spacer()
                        let minPercent = Int(Double(result.minDamage) / Double(result.defenderMaxHP) * 100)
                        let maxPercent = Int(Double(result.maxDamage) / Double(result.defenderMaxHP) * 100)
                        Text("\(minPercent)% ~ \(maxPercent)%")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.trailing, 4)
                    }
                }
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .frame(height: 32)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Sections

    /// プリセット選択セクション
    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "damage_calc.preset"))
                    .font(.headline)

                Spacer()

                Button(action: {
                    Task {
                        let presetName = String(localized: "damage_calc.preset_name_format", defaultValue: "Preset \(store.presets.count + 1)")
                        try? await store.savePreset(name: String(format: presetName, store.presets.count + 1))
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                        Text(String(localized: "damage_calc.preset_save"))
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }

            if !store.presets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.presets) { preset in
                            ZStack(alignment: .topTrailing) {
                                Button(action: {
                                    store.loadPreset(preset)
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(preset.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Text(preset.createdAt, style: .date)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        store.selectedPreset?.id == preset.id
                                            ? Color.blue.opacity(0.2)
                                            : Color.gray.opacity(0.1)
                                    )
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                store.selectedPreset?.id == preset.id
                                                    ? Color.blue
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                }
                                .buttonStyle(.plain)

                                // 削除ボタン
                                Button(action: {
                                    Task {
                                        try? await store.deletePreset(preset)
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                        .padding(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text(String(localized: "damage_calc.preset_empty"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .task {
            await store.loadPresets()
        }
    }

    /// バトルモード切替セクション
    private var battleModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "damage_calc.battle_mode"))
                .font(.headline)

            Picker("", selection: Binding(
                get: { store.battleState.mode },
                set: { _ in store.toggleBattleMode() }
            )) {
                ForEach(BattleMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    /// 参加者（攻撃側/防御側）セクション
    private func participantSection(
        title: String,
        participant: BattleParticipantState,
        isAttacker: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            // ポケモン選択
            pokemonSelectionRow(participant: participant, isAttacker: isAttacker)

            // レベル
            levelRow(participant: participant, isAttacker: isAttacker)

            // テラスタル
            teraRow(participant: participant, isAttacker: isAttacker)

            // アイテム
            itemRow(participant: participant, isAttacker: isAttacker)

            // ステータス設定（努力値・個体値・性格）
            statsConfigRow(participant: participant, isAttacker: isAttacker)

            // ランク補正
            rankBoostRow(participant: participant, isAttacker: isAttacker)

            // 特性
            abilityRow(participant: participant, isAttacker: isAttacker)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    /// ポケモン選択行
    private func pokemonSelectionRow(participant: BattleParticipantState, isAttacker: Bool) -> some View {
        Button(action: {
            if isAttacker {
                showingAttackerPokemonSelector = true
            } else {
                showingDefenderPokemonSelector = true
            }
        }) {
            HStack(spacing: 12) {
                // スプライト画像
                if let spriteURL = participant.spriteURL, let url = URL(string: spriteURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "plus.circle")
                                .foregroundColor(.secondary)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "damage_calc.pokemon"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(participant.pokemonName ?? String(localized: "damage_calc.not_selected"))
                        .font(.body)
                        .foregroundColor(participant.pokemonName == nil ? .secondary : .primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    /// レベル行
    private func levelRow(participant: BattleParticipantState, isAttacker: Bool) -> some View {
        HStack {
            Text(String(localized: "damage_calc.level"))
                .foregroundColor(.secondary)

            Spacer()

            Text("\(participant.level)")
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }

    /// テラスタル行
    private func teraRow(participant: BattleParticipantState, isAttacker: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "damage_calc.terastallize"))
                    .foregroundColor(.secondary)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { participant.isTerastallized },
                    set: { _ in
                        if isAttacker {
                            store.toggleAttackerTerastallize()
                        } else {
                            store.toggleDefenderTerastallize()
                        }
                    }
                ))
            }

            // テラスタルがオンの時はテラスタイプを選択
            if participant.isTerastallized {
                HStack {
                    Text(String(localized: "damage_calc.tera_type"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Picker("", selection: Binding(
                        get: { participant.teraType ?? "normal" },
                        set: { newType in
                            if isAttacker {
                                store.setAttackerTeraType(newType)
                            } else {
                                store.setDefenderTeraType(newType)
                            }
                        }
                    )) {
                        ForEach(allPokemonTypes, id: \.self) { type in
                            Text(typeDisplayName(type)).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .padding(.vertical, 8)
    }

    /// 全ポケモンタイプ（テラスタル用、ステラタイプを含む）
    private let allPokemonTypes = [
        "normal", "fire", "water", "grass", "electric", "ice",
        "fighting", "poison", "ground", "flying", "psychic", "bug",
        "rock", "ghost", "dragon", "dark", "steel", "fairy", "stellar"
    ]

    /// タイプの日本語名
    private func typeDisplayName(_ type: String) -> String {
        switch type.lowercased() {
        case "normal": return "ノーマル"
        case "fire": return "ほのお"
        case "water": return "みず"
        case "grass": return "くさ"
        case "electric": return "でんき"
        case "ice": return "こおり"
        case "fighting": return "かくとう"
        case "poison": return "どく"
        case "ground": return "じめん"
        case "flying": return "ひこう"
        case "psychic": return "エスパー"
        case "bug": return "むし"
        case "rock": return "いわ"
        case "ghost": return "ゴースト"
        case "dragon": return "ドラゴン"
        case "dark": return "あく"
        case "steel": return "はがね"
        case "fairy": return "フェアリー"
        case "stellar": return "ステラ"
        default: return type.capitalized
        }
    }

    /// アイテム行
    private func itemRow(participant: BattleParticipantState, isAttacker: Bool) -> some View {
        Button(action: {
            if isAttacker {
                showingAttackerItemSelector = true
            } else {
                showingDefenderItemSelector = true
            }
        }) {
            HStack {
                Text(String(localized: "damage_calc.held_item"))
                    .foregroundColor(.secondary)

                Spacer()

                if let itemId = participant.heldItemId,
                   let item = store.availableItems.first(where: { $0.id == itemId }) {
                    Text(item.nameJa)
                        .foregroundColor(.primary)
                } else {
                    Text(String(localized: "damage_calc.none"))
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 特性選択行
    private func abilityRow(participant: BattleParticipantState, isAttacker: Bool) -> some View {
        Button(action: {
            if isAttacker {
                showingAttackerAbilitySelector = true
            } else {
                showingDefenderAbilitySelector = true
            }
        }) {
            HStack {
                Text(String(localized: "damage_calc.ability"))
                    .foregroundColor(.secondary)

                Spacer()

                if let abilityId = participant.abilityId,
                   let ability = store.availableAbilities.first(where: { $0.id == abilityId }) {
                    Text(ability.nameJa)
                        .foregroundColor(.primary)
                } else {
                    Text(String(localized: "damage_calc.not_selected"))
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// ステータス設定行
    private func statsConfigRow(participant: BattleParticipantState, isAttacker: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 性格選択
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "damage_calc.nature"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        if isAttacker {
                            // 攻撃側: こうげき↑↓ / とくこう↑↓
                            simpleNatureButton(title: String(localized: "damage_calc.nature_attack_up"), nature: .adamant, participant: participant, isAttacker: isAttacker)
                            simpleNatureButton(title: String(localized: "damage_calc.nature_attack_down"), nature: .modest, participant: participant, isAttacker: isAttacker)
                            simpleNatureButton(title: String(localized: "damage_calc.nature_sp_attack_up"), nature: .modest, participant: participant, isAttacker: isAttacker)
                            simpleNatureButton(title: String(localized: "damage_calc.nature_sp_attack_down"), nature: .adamant, participant: participant, isAttacker: isAttacker)
                        } else {
                            // 防御側: ぼうぎょ↑↓ / とくぼう↑↓
                            simpleNatureButton(title: String(localized: "damage_calc.nature_defense_up"), nature: .bold, participant: participant, isAttacker: isAttacker)
                            simpleNatureButton(title: String(localized: "damage_calc.nature_defense_down"), nature: .gentle, participant: participant, isAttacker: isAttacker)
                            simpleNatureButton(title: String(localized: "damage_calc.nature_sp_defense_up"), nature: .calm, participant: participant, isAttacker: isAttacker)
                            simpleNatureButton(title: String(localized: "damage_calc.nature_sp_defense_down"), nature: .lax, participant: participant, isAttacker: isAttacker)
                        }
                    }
                }
            }

            Divider()

            // ステータス入力（攻撃側と防御側で異なる）
            if isAttacker {
                // 攻撃側: A, C
                statInputRow(title: String(localized: "stat.attack"), stat: "attack", participant: participant, isAttacker: isAttacker)
                statInputRow(title: String(localized: "stat.special_attack"), stat: "special-attack", participant: participant, isAttacker: isAttacker)
            } else {
                // 防御側: H, B, D
                statInputRow(title: String(localized: "stat.hp"), stat: "hp", participant: participant, isAttacker: isAttacker)
                statInputRow(title: String(localized: "stat.defense"), stat: "defense", participant: participant, isAttacker: isAttacker)
                statInputRow(title: String(localized: "stat.special_defense"), stat: "special-defense", participant: participant, isAttacker: isAttacker)
            }
        }
        .padding(.vertical, 8)
    }

    /// 個別ステータス入力行
    private func statInputRow(title: String, stat: String, participant: BattleParticipantState, isAttacker: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // 性格補正の矢印
                    let natureModifier = participant.nature.modifier(for: stat)
                    if natureModifier > 1.0 {
                        Text("↑")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if natureModifier < 1.0 {
                        Text("↓")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .frame(width: 80, alignment: .leading)

                Spacer()

                // 実数値
                Text("\(getActualStat(participant: participant, stat: stat))")
                    .font(.body)
                    .foregroundColor(.primary)
                    .bold()
            }

            // 個体値
            HStack(spacing: 8) {
                Text(String(localized: "damage_calc.iv"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .leading)

                Stepper("\(getIV(participant: participant, stat: stat))",
                        value: Binding(
                            get: { getIV(participant: participant, stat: stat) },
                            set: { updateIV(participant: participant, stat: stat, value: $0, isAttacker: isAttacker) }
                        ),
                        in: 0...31)
            }

            // 努力値
            HStack(spacing: 8) {
                Text(String(localized: "damage_calc.ev"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .leading)

                Stepper("\(getEV(participant: participant, stat: stat))",
                        value: Binding(
                            get: { getEV(participant: participant, stat: stat) },
                            set: { updateEV(participant: participant, stat: stat, value: $0, isAttacker: isAttacker) }
                        ),
                        in: 0...252,
                        step: 4)
            }

            Divider()
                .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Nature Selection

    /// シンプルな性格選択ボタン
    private func simpleNatureButton(
        title: String,
        nature: Nature,
        participant: BattleParticipantState,
        isAttacker: Bool
    ) -> some View {
        // タイトルから判定：「こうげき↑」などの上昇/下降を検出
        let isIncreaseButton = title.contains("↑")
        let isDecreaseButton = title.contains("↓")
        let isNoneButton = title == "なし"

        let isSelected: Bool = {
            if isNoneButton {
                return participant.nature.simpleNotation == "-"
            }

            // ボタンのステータスを特定
            var statName: String? = nil
            if title.contains("こうげき") {
                statName = "attack"
            } else if title.contains("とくこう") {
                statName = "special-attack"
            } else if title.contains("ぼうぎょ") {
                statName = "defense"
            } else if title.contains("とくぼう") {
                statName = "special-defense"
            }

            guard let stat = statName else { return false }

            let modifier = participant.nature.modifier(for: stat)
            if isIncreaseButton {
                return modifier > 1.0
            } else if isDecreaseButton {
                return modifier < 1.0
            }

            return false
        }()

        return Button(action: {
            if isAttacker {
                store.updateAttackerNature(nature)
            } else {
                store.updateDefenderNature(nature)
            }
        }) {
            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(6)
        }
    }

    // MARK: - Stat Getters/Setters

    private func getIV(participant: BattleParticipantState, stat: String) -> Int {
        switch stat {
        case "hp": return participant.individualValues.hp
        case "attack": return participant.individualValues.attack
        case "defense": return participant.individualValues.defense
        case "special-attack": return participant.individualValues.specialAttack
        case "special-defense": return participant.individualValues.specialDefense
        case "speed": return participant.individualValues.speed
        default: return 31
        }
    }

    private func getEV(participant: BattleParticipantState, stat: String) -> Int {
        switch stat {
        case "hp": return participant.effortValues.hp
        case "attack": return participant.effortValues.attack
        case "defense": return participant.effortValues.defense
        case "special-attack": return participant.effortValues.specialAttack
        case "special-defense": return participant.effortValues.specialDefense
        case "speed": return participant.effortValues.speed
        default: return 0
        }
    }

    private func getActualStat(participant: BattleParticipantState, stat: String) -> Int {
        let base = participant.baseStats[stat] ?? 100
        let iv = getIV(participant: participant, stat: stat)
        let ev = getEV(participant: participant, stat: stat)
        let natureModifier = participant.nature.modifier(for: stat)
        return calculateActualStat(statName: stat, base: base, iv: iv, ev: ev, level: participant.level, natureModifier: natureModifier)
    }

    private func updateIV(participant: BattleParticipantState, stat: String, value: Int, isAttacker: Bool) {
        var ivs = participant.individualValues
        switch stat {
        case "hp": ivs.hp = value
        case "attack": ivs.attack = value
        case "defense": ivs.defense = value
        case "special-attack": ivs.specialAttack = value
        case "special-defense": ivs.specialDefense = value
        case "speed": ivs.speed = value
        default: break
        }

        if isAttacker {
            store.updateAttackerIndividualValues(ivs)
        } else {
            store.updateDefenderIndividualValues(ivs)
        }
    }

    private func updateEV(participant: BattleParticipantState, stat: String, value: Int, isAttacker: Bool) {
        var evs = participant.effortValues
        switch stat {
        case "hp": evs.hp = value
        case "attack": evs.attack = value
        case "defense": evs.defense = value
        case "special-attack": evs.specialAttack = value
        case "special-defense": evs.specialDefense = value
        case "speed": evs.speed = value
        default: break
        }

        if isAttacker {
            store.updateAttackerEffortValues(evs)
        } else {
            store.updateDefenderEffortValues(evs)
        }
    }

    /// 平均個体値を計算
    private func averageIV(_ ivs: IndividualValueSet) -> String {
        let total = ivs.hp + ivs.attack + ivs.defense + ivs.specialAttack + ivs.specialDefense + ivs.speed
        let average = Double(total) / 6.0
        return String(format: "%.1f", average)
    }

    /// 実数値を計算
    private func calculateActualStat(
        statName: String,
        base: Int,
        iv: Int,
        ev: Int,
        level: Int,
        natureModifier: Double
    ) -> Int {
        if statName == "hp" {
            return Int(floor(Double((base * 2 + iv + ev / 4) * level) / 100.0)) + level + 10
        } else {
            let baseStat = Int(floor(Double((base * 2 + iv + ev / 4) * level) / 100.0)) + 5
            return Int(floor(Double(baseStat) * natureModifier))
        }
    }

    /// 技選択セクション
    private var moveSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 複数ターンモード切り替え
            Toggle(String(localized: "damage_calc.multi_turn"), isOn: $isMultiTurnMode)
                .toggleStyle(.switch)
                .onChange(of: isMultiTurnMode) { _, newValue in
                    if !newValue {
                        // 単一ターンモードに戻る場合、複数ターンデータをクリア
                        store.clearTurns()
                    } else {
                        // 複数ターンモードに切り替える場合、現在の技を1ターン目に設定
                        if let moveId = store.battleState.selectedMoveId {
                            store.battleState.turnMoves = [moveId]
                        }
                    }
                }

            if isMultiTurnMode {
                // 複数ターンモード
                multiTurnMoveSelection
            } else {
                // 単一ターンモード
                singleTurnMoveSelection
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    /// 単一ターンの技選択
    private var singleTurnMoveSelection: some View {
        Button(action: {
            selectingTurnIndex = nil
            showingMoveSelector = true
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "damage_calc.move"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let move = store.selectedMove {
                        HStack(spacing: 8) {
                            Text(move.nameJa)
                                .font(.body)
                                .foregroundColor(.primary)

                            // タイプバッジ
                            Text(move.type.nameJa ?? move.type.japaneseName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(move.type.color)
                                .foregroundColor(move.type.textColor)
                                .cornerRadius(4)

                            // 威力
                            if let power = move.power {
                                Text("威力: \(power)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Text(String(localized: "damage_calc.not_selected"))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    /// 複数ターンの技選択
    private var multiTurnMoveSelection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(store.battleState.turnMoves.enumerated()), id: \.offset) { index, moveId in
                turnMoveRow(turnNumber: index + 1, moveId: moveId, index: index)
            }

            // ターン追加ボタン
            Button(action: {
                // デフォルトで最初の技を追加（または未選択）
                if let firstMoveId = store.battleState.turnMoves.first {
                    store.addTurn(moveId: firstMoveId)
                } else if let moveId = store.battleState.selectedMoveId {
                    store.addTurn(moveId: moveId)
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(String(localized: "damage_calc.add_turn"))
                }
                .foregroundColor(.blue)
                .font(.subheadline)
            }
        }
    }

    /// ターンごとの技選択行
    private func turnMoveRow(turnNumber: Int, moveId: Int, index: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(turnNumber)T:")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)

            Button(action: {
                selectingTurnIndex = index
                showingMoveSelector = true
            }) {
                HStack(spacing: 8) {
                    if let move = store.availableMoves.first(where: { $0.id == moveId }) {
                        Text(move.nameJa)
                            .font(.body)
                            .foregroundColor(.primary)

                        Text(move.type.nameJa ?? move.type.japaneseName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(move.type.color)
                            .foregroundColor(move.type.textColor)
                            .cornerRadius(4)

                        if let power = move.power {
                            Text("威力: \(power)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(String(format: NSLocalizedString("damage_calc.move_id", comment: ""), moveId))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            // 削除ボタン
            Button(action: {
                store.removeTurn(at: index)
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }

    /// 入れ替えボタン
    private var swapButton: some View {
        Button(action: {
            store.swapAttackerAndDefender()
        }) {
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                Text(String(localized: "damage_calc.swap"))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    /// バトル環境セクション
    private var environmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "damage_calc.environment"))
                .font(.headline)

            // 天候
            weatherRow

            // フィールド
            terrainRow

            // 壁
            screenRow
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    /// 天候行
    private var weatherRow: some View {
        HStack {
            Text(String(localized: "damage_calc.weather"))
                .foregroundColor(.secondary)

            Spacer()

            Picker("", selection: Binding<WeatherCondition>(
                get: { store.battleState.environment.weather ?? WeatherCondition.none },
                set: { store.battleState.environment.weather = ($0 == WeatherCondition.none ? nil : $0) }
            )) {
                ForEach(WeatherCondition.allCases) { weather in
                    Text(weather.displayName).tag(weather)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.vertical, 8)
    }

    /// フィールド行
    private var terrainRow: some View {
        HStack {
            Text(String(localized: "damage_calc.terrain"))
                .foregroundColor(.secondary)

            Spacer()

            Picker("", selection: Binding<TerrainField>(
                get: { store.battleState.environment.terrain ?? TerrainField.none },
                set: { store.battleState.environment.terrain = ($0 == TerrainField.none ? nil : $0) }
            )) {
                ForEach(TerrainField.allCases) { terrain in
                    Text(terrain.displayName).tag(terrain)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.vertical, 8)
    }

    /// 壁行
    private var screenRow: some View {
        HStack {
            Text(String(localized: "damage_calc.screen"))
                .foregroundColor(.secondary)

            Spacer()

            Picker("", selection: Binding<ScreenEffect>(
                get: { store.battleState.environment.screen ?? ScreenEffect.none },
                set: { store.battleState.environment.screen = ($0 == ScreenEffect.none ? nil : $0) }
            )) {
                ForEach(ScreenEffect.allCases) { screen in
                    Text(screen.displayName).tag(screen)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.vertical, 8)
    }

    /// 複数ターンの結果表示
    private var multiTurnResultView: some View {
        Group {
            if let result = store.multiTurnResult {
                VStack(alignment: .leading, spacing: 16) {
                    // 各ターンの結果
                    ForEach(Array(result.turns.enumerated()), id: \.offset) { index, turn in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(format: NSLocalizedString("damage_calc.turn_format", comment: ""), turn.turnNumber, turn.moveName))
                                .font(.headline)

                            HStack {
                                Text("ダメージ:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(turn.damageResult.minDamage) ~ \(turn.damageResult.maxDamage)")
                                    .font(.body)
                                    .bold()
                            }

                            HStack {
                                Text("ダメージ割合:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                let minPercent = Int(Double(turn.damageResult.minDamage) / Double(result.defenderMaxHP) * 100)
                                let maxPercent = Int(Double(turn.damageResult.maxDamage) / Double(result.defenderMaxHP) * 100)
                                Text("\(minPercent)% ~ \(maxPercent)%")
                                    .font(.caption)
                            }

                            // 補正倍率（1.0以外のみ表示）
                            VStack(alignment: .leading, spacing: 4) {
                                modifierRow(label: String(localized: "damage_calc.modifier_stab"), multiplier: turn.damageResult.modifiers.stab)
                                modifierRow(label: String(localized: "damage_calc.modifier_type_effectiveness"), multiplier: turn.damageResult.modifiers.typeEffectiveness)
                                modifierRow(label: String(localized: "damage_calc.modifier_weather"), multiplier: turn.damageResult.modifiers.weather)
                                modifierRow(label: String(localized: "damage_calc.modifier_terrain"), multiplier: turn.damageResult.modifiers.terrain)
                                modifierRow(label: String(localized: "damage_calc.modifier_screen"), multiplier: turn.damageResult.modifiers.screen)
                                modifierRow(label: String(localized: "damage_calc.modifier_item"), multiplier: turn.damageResult.modifiers.item)
                                modifierRow(label: String(localized: "damage_calc.modifier_other"), multiplier: turn.damageResult.modifiers.other)

                                HStack {
                                    Text(String(localized: "damage_calc.total_multiplier"))
                                        .font(.caption)
                                        .bold()
                                    Spacer()
                                    Text("×\(turn.damageResult.modifiers.total, specifier: "%.3f")")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.blue)
                                }
                            }

                            Divider()
                        }
                    }

                    // 累積ダメージ範囲
                    let totalRange = result.totalDamageRange
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(localized: "damage_calc.cumulative_damage"))
                                .font(.headline)
                            Spacer()
                            Text("\(totalRange.min) ~ \(totalRange.max)")
                                .font(.title3)
                                .bold()
                        }

                        HStack {
                            Text("ダメージ割合:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            let minPercent = Int(Double(totalRange.min) / Double(result.defenderMaxHP) * 100)
                            let maxPercent = Int(Double(totalRange.max) / Double(result.defenderMaxHP) * 100)
                            Text("\(minPercent)% ~ \(maxPercent)%")
                                .font(.caption)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Text(String(localized: "damage_calc.select_turns"))
                        .foregroundColor(.secondary)
                        .font(.subheadline)

                    if store.isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                            Text("計算中...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
    }

    /// 撃破確率に応じた色
    private func koColor(_ probability: Double) -> Color {
        if probability >= 1.0 {
            return .green
        } else if probability >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    /// 結果表示セクション
    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let error = store.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if isMultiTurnMode {
                // 複数ターンモードの結果表示
                multiTurnResultView
            } else if let result = store.damageResult {
                // 単一ターンモードの結果表示
                VStack(alignment: .leading, spacing: 12) {
                    // HPバー可視化（ダメージ範囲）
                    damageRangeBar(result: result)

                    HStack {
                        Text("ダメージ:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(result.minDamage) ~ \(result.maxDamage)")
                            .font(.title3)
                            .bold()
                    }

                    HStack {
                        Text("確定数:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(result.hitsToKO)発")
                            .font(.title3)
                            .bold()
                    }

                    Divider()

                    Text("補正倍率")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 6) {
                        modifierRow(label: String(localized: "damage_calc.modifier_stab"), multiplier: result.modifiers.stab)
                        modifierRow(label: String(localized: "damage_calc.modifier_type_effectiveness"), multiplier: result.modifiers.typeEffectiveness)
                        modifierRow(label: String(localized: "damage_calc.modifier_weather"), multiplier: result.modifiers.weather)
                        modifierRow(label: String(localized: "damage_calc.modifier_terrain"), multiplier: result.modifiers.terrain)
                        modifierRow(label: String(localized: "damage_calc.modifier_screen"), multiplier: result.modifiers.screen)
                        modifierRow(label: String(localized: "damage_calc.modifier_item"), multiplier: result.modifiers.item)
                        modifierRow(label: String(localized: "damage_calc.modifier_other"), multiplier: result.modifiers.other)

                        Divider()
                            .padding(.vertical, 4)

                        HStack {
                            Text(String(localized: "damage_calc.total_multiplier"))
                                .font(.headline)
                            Spacer()
                            Text("×\(result.modifiers.total, specifier: "%.3f")")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Text(String(localized: "damage_calc.select_pokemon_and_move"))
                        .foregroundColor(.secondary)
                        .font(.subheadline)

                    if store.isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                            Text("計算中...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    /// ランク補正入力行
    private func rankBoostRow(participant: BattleParticipantState, isAttacker: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "damage_calc.rank_boost"))
                .font(.caption)
                .foregroundColor(.secondary)

            if isAttacker {
                // 攻撃側: こうげき、とくこう
                rankStageControl(title: String(localized: "stat.attack"), stage: participant.statStages.attack, isAttacker: isAttacker) { newValue in
                    store.battleState.attacker.statStages = StatStageSet(
                        attack: newValue,
                        defense: participant.statStages.defense,
                        specialAttack: participant.statStages.specialAttack,
                        specialDefense: participant.statStages.specialDefense,
                        speed: participant.statStages.speed
                    )
                }
                rankStageControl(title: String(localized: "stat.special_attack"), stage: participant.statStages.specialAttack, isAttacker: isAttacker) { newValue in
                    store.battleState.attacker.statStages = StatStageSet(
                        attack: participant.statStages.attack,
                        defense: participant.statStages.defense,
                        specialAttack: newValue,
                        specialDefense: participant.statStages.specialDefense,
                        speed: participant.statStages.speed
                    )
                }
            } else {
                // 防御側: ぼうぎょ、とくぼう
                rankStageControl(title: String(localized: "stat.defense"), stage: participant.statStages.defense, isAttacker: isAttacker) { newValue in
                    store.battleState.defender.statStages = StatStageSet(
                        attack: participant.statStages.attack,
                        defense: newValue,
                        specialAttack: participant.statStages.specialAttack,
                        specialDefense: participant.statStages.specialDefense,
                        speed: participant.statStages.speed
                    )
                }
                rankStageControl(title: String(localized: "stat.special_defense"), stage: participant.statStages.specialDefense, isAttacker: isAttacker) { newValue in
                    store.battleState.defender.statStages = StatStageSet(
                        attack: participant.statStages.attack,
                        defense: participant.statStages.defense,
                        specialAttack: participant.statStages.specialAttack,
                        specialDefense: newValue,
                        speed: participant.statStages.speed
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }

    /// 単一ステータスのランク補正コントロール
    private func rankStageControl(
        title: String,
        stage: Int,
        isAttacker: Bool,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Spacer()

            // マイナスボタン
            Button(action: {
                let newStage = max(-6, stage - 1)
                onChange(newStage)
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(stage > -6 ? .blue : .gray)
            }
            .disabled(stage <= -6)
            .buttonStyle(.plain)

            // 現在値表示
            Text(stage > 0 ? "+\(stage)" : "\(stage)")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(
                    stage > 0 ? .red :
                    stage < 0 ? .blue :
                    .secondary
                )
                .frame(width: 40)

            // プラスボタン
            Button(action: {
                let newStage = min(6, stage + 1)
                onChange(newStage)
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(stage < 6 ? .red : .gray)
            }
            .disabled(stage >= 6)
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct DamageCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        // PreviewはSwiftDataが使用できないため、簡易的なプレビューとして空状態を表示
        Text("Preview is not available for DamageCalculatorView")
            .foregroundColor(.secondary)
    }
}
