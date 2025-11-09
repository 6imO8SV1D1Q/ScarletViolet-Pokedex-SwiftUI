//
//  DamageCalculatorStore.swift
//  Pokedex
//
//  Created on 2025-11-01.
//

import Foundation
import SwiftUI
import Combine

/// ダメージ計算画面の状態管理
@MainActor
final class DamageCalculatorStore: ObservableObject {
    // MARK: - Published Properties

    /// バトル状態
    @Published var battleState: BattleState

    /// 計算結果（単一ターン）
    @Published var damageResult: DamageResult?

    /// 計算結果（複数ターン）
    @Published var multiTurnResult: MultiTurnDamageResult?

    /// ローディング状態
    @Published var isLoading: Bool = false

    /// エラーメッセージ
    @Published var errorMessage: String?

    /// プリセット一覧
    @Published var presets: [BattlePreset] = []

    /// 選択中のプリセット
    @Published var selectedPreset: BattlePreset?

    /// ポケモン一覧（選択用）
    @Published var availablePokemons: [Pokemon] = []

    /// 技一覧（選択用）
    @Published var availableMoves: [MoveEntity] = []

    /// 選択中の技情報
    @Published var selectedMove: MoveEntity?

    /// 特性一覧（選択用）
    @Published var availableAbilities: [AbilityEntity] = []

    /// アイテム一覧（選択用）
    @Published var availableItems: [ItemEntity] = []

    // MARK: - Dependencies

    private let itemProvider: ItemProviderProtocol
    private let presetStore: BattlePresetStore
    private let pokemonRepository: PokemonRepositoryProtocol
    private let moveRepository: MoveRepositoryProtocol
    private let typeRepository: TypeRepositoryProtocol
    private let abilityRepository: AbilityRepositoryProtocol

    // MARK: - Initialization

    init(
        itemProvider: ItemProviderProtocol,
        presetStore: BattlePresetStore = BattlePresetStore(),
        pokemonRepository: PokemonRepositoryProtocol,
        moveRepository: MoveRepositoryProtocol,
        typeRepository: TypeRepositoryProtocol,
        abilityRepository: AbilityRepositoryProtocol
    ) {
        self.itemProvider = itemProvider
        self.presetStore = presetStore
        self.pokemonRepository = pokemonRepository
        self.moveRepository = moveRepository
        self.typeRepository = typeRepository
        self.abilityRepository = abilityRepository
        self.battleState = BattleState()
    }

    // MARK: - Actions

    /// バトルモードを切り替える
    func toggleBattleMode() {
        battleState.mode = battleState.mode == .single ? .double : .single
    }

    /// 攻撃側と防御側を入れ替える
    func swapAttackerAndDefender() {
        battleState.swap()
    }

    /// 状態をリセット
    func reset() {
        battleState.reset()
        damageResult = nil
        errorMessage = nil
    }

    /// ポケモンを選択（攻撃側）
    func selectAttackerPokemon(_ pokemon: Pokemon) {
        battleState.attacker.pokemonId = pokemon.id
        battleState.attacker.pokemonName = pokemon.displayName
        battleState.attacker.baseTypes = pokemon.types.map { $0.name }
        battleState.attacker.spriteURL = pokemon.displayImageURL

        // 種族値をセット
        var baseStats: [String: Int] = [:]
        for stat in pokemon.stats {
            baseStats[stat.name] = stat.baseStat
        }
        battleState.attacker.baseStats = baseStats
    }

    /// ポケモンを選択（防御側）
    func selectDefenderPokemon(_ pokemon: Pokemon) {
        battleState.defender.pokemonId = pokemon.id
        battleState.defender.pokemonName = pokemon.displayName
        battleState.defender.baseTypes = pokemon.types.map { $0.name }
        battleState.defender.spriteURL = pokemon.displayImageURL

        // 種族値をセット
        var baseStats: [String: Int] = [:]
        for stat in pokemon.stats {
            baseStats[stat.name] = stat.baseStat
        }
        battleState.defender.baseStats = baseStats
    }

    /// 技を選択
    func selectMove(_ move: MoveEntity) {
        battleState.selectedMoveId = move.id
        selectedMove = move
    }

    /// アイテムを選択（攻撃側）
    func selectAttackerItem(id: Int?) {
        battleState.attacker.heldItemId = id
    }

    /// アイテムを選択（防御側）
    func selectDefenderItem(id: Int?) {
        battleState.defender.heldItemId = id
    }

    /// テラスタルを切り替え（攻撃側）
    func toggleAttackerTerastallize() {
        battleState.attacker.isTerastallized.toggle()
        // テラスタルをオンにした時、テラスタイプが未設定なら通常タイプの最初を設定
        if battleState.attacker.isTerastallized && battleState.attacker.teraType == nil {
            battleState.attacker.teraType = battleState.attacker.baseTypes.first ?? "normal"
        }
    }

    /// テラスタルを切り替え（防御側）
    func toggleDefenderTerastallize() {
        battleState.defender.isTerastallized.toggle()
        // テラスタルをオンにした時、テラスタイプが未設定なら通常タイプの最初を設定
        if battleState.defender.isTerastallized && battleState.defender.teraType == nil {
            battleState.defender.teraType = battleState.defender.baseTypes.first ?? "normal"
        }
    }

    /// テラスタイプを設定（攻撃側）
    func setAttackerTeraType(_ type: String) {
        battleState.attacker.teraType = type
    }

    /// テラスタイプを設定（防御側）
    func setDefenderTeraType(_ type: String) {
        battleState.defender.teraType = type
    }

    /// ダメージ計算を実行
    func calculateDamage() async {
        isLoading = true
        defer { isLoading = false }

        // バリデーション
        guard battleState.attacker.pokemonId != nil,
              battleState.defender.pokemonId != nil,
              battleState.selectedMoveId != nil else {
            errorMessage = "ポケモンと技を選択してください"
            return
        }

        do {
            // アイテムを取得
            let attackerItem: ItemEntity? = if let itemId = battleState.attacker.heldItemId {
                try await itemProvider.fetchItem(id: itemId)
            } else {
                nil
            }

            // 技情報を取得
            guard let moveId = battleState.selectedMoveId else {
                errorMessage = "技が選択されていません"
                return
            }

            let move = try await moveRepository.fetchMoveDetail(moveId: moveId, versionGroup: nil)
            guard let movePower = move.power else {
                errorMessage = "選択された技は攻撃技ではありません"
                return
            }

            let moveType = move.type.name
            let isPhysical = move.damageClass == "physical"

            // 実際の種族値を取得
            let attackerBaseAttack = battleState.attacker.baseStats["attack"] ?? 100
            let attackerBaseSpecialAttack = battleState.attacker.baseStats["special-attack"] ?? 100
            let defenderBaseDefense = battleState.defender.baseStats["defense"] ?? 100
            let defenderBaseSpecialDefense = battleState.defender.baseStats["special-defense"] ?? 100
            let defenderBaseHP = battleState.defender.baseStats["hp"] ?? 100

            // 性格補正を取得
            let attackerNatureAttack = battleState.attacker.nature.modifier(for: "attack")
            let attackerNatureSpecialAttack = battleState.attacker.nature.modifier(for: "special-attack")
            let defenderNatureDefense = battleState.defender.nature.modifier(for: "defense")
            let defenderNatureSpecialDefense = battleState.defender.nature.modifier(for: "special-defense")

            // ステータス計算
            var attackStat = DamageFormulaEngine.calculateStat(
                base: isPhysical ? attackerBaseAttack : attackerBaseSpecialAttack,
                level: battleState.attacker.level,
                iv: isPhysical ? battleState.attacker.individualValues.attack : battleState.attacker.individualValues.specialAttack,
                ev: isPhysical ? battleState.attacker.effortValues.attack : battleState.attacker.effortValues.specialAttack,
                nature: isPhysical ? attackerNatureAttack : attackerNatureSpecialAttack,
                statStage: isPhysical ? battleState.attacker.statStages.attack : battleState.attacker.statStages.specialAttack
            )

            // 攻撃側の特性によるステータス補正（ちからもち、ヨガパワーなど）
            let attackerStatMultiplier = BattleModifierResolver.getAttackerStatMultiplier(
                abilityId: battleState.attacker.abilityId,
                isPhysical: isPhysical
            )
            attackStat = Int(Double(attackStat) * attackerStatMultiplier)

            var defenseStat = DamageFormulaEngine.calculateStat(
                base: isPhysical ? defenderBaseDefense : defenderBaseSpecialDefense,
                level: battleState.defender.level,
                iv: isPhysical ? battleState.defender.individualValues.defense : battleState.defender.individualValues.specialDefense,
                ev: isPhysical ? battleState.defender.effortValues.defense : battleState.defender.effortValues.specialDefense,
                nature: isPhysical ? defenderNatureDefense : defenderNatureSpecialDefense,
                statStage: isPhysical ? battleState.defender.statStages.defense : battleState.defender.statStages.specialDefense
            )

            // 防御側の特性によるステータス補正（ファーコートなど）
            let defenderStatMultiplier = BattleModifierResolver.getDefenderStatMultiplier(
                abilityId: battleState.defender.abilityId,
                isPhysical: isPhysical
            )
            defenseStat = Int(Double(defenseStat) * defenderStatMultiplier)

            let defenderMaxHP = DamageFormulaEngine.calculateHP(
                base: defenderBaseHP,
                level: battleState.defender.level,
                iv: battleState.defender.individualValues.hp,
                ev: battleState.defender.effortValues.hp
            )

            // タイプ相性を計算
            let defenderTypes = battleState.defender.isTerastallized
                ? [battleState.defender.teraType].compactMap { $0 }
                : battleState.defender.baseTypes

            var typeEffectiveness = 1.0
            let moveTypeDetail = try await typeRepository.fetchTypeDetail(typeName: moveType)

            for defenderType in defenderTypes {
                if moveTypeDetail.damageRelations.doubleDamageTo.contains(defenderType) {
                    typeEffectiveness *= 2.0
                } else if moveTypeDetail.damageRelations.halfDamageTo.contains(defenderType) {
                    typeEffectiveness *= 0.5
                } else if moveTypeDetail.damageRelations.noDamageTo.contains(defenderType) {
                    typeEffectiveness = 0.0
                    break
                }
            }

            // 補正を計算
            let modifiers = BattleModifierResolver.resolveModifiers(
                battleState: battleState,
                moveType: moveType,
                isPhysical: isPhysical,
                movePower: movePower,
                attackerItem: attackerItem,
                typeEffectiveness: typeEffectiveness
            )

            // ダメージを計算
            let damageRange = DamageFormulaEngine.calculateDamage(
                attackerLevel: battleState.attacker.level,
                movePower: movePower,
                attackStat: attackStat,
                defenseStat: defenseStat,
                modifiers: modifiers
            )

            let minDamage = damageRange.min() ?? 0
            let maxDamage = damageRange.max() ?? 0

            // 撃破確率を計算
            let koChance = ProbabilityCalculator.calculateKOProbability(
                damageRange: damageRange,
                targetHP: defenderMaxHP
            )

            // 確定数を計算
            let hitsToKO = defenderMaxHP > 0 ? Int(ceil(Double(defenderMaxHP) / Double(maxDamage))) : 0

            // 平均ダメージを計算
            let averageDamage = ProbabilityCalculator.calculateAverageDamage(damageRange: damageRange)

            // 2ターン撃破確率を計算（簡易版：同じ技を使用）
            let twoTurnKOChance = ProbabilityCalculator.calculateTwoTurnKOProbability(
                firstTurnDamage: damageRange,
                secondTurnDamage: damageRange,
                targetHP: defenderMaxHP
            )

            // 結果を設定
            damageResult = DamageResult(
                minDamage: minDamage,
                maxDamage: maxDamage,
                damageRange: damageRange,
                koChance: koChance,
                hitsToKO: hitsToKO,
                defenderMaxHP: defenderMaxHP,
                modifiers: modifiers,
                twoTurnKOChance: twoTurnKOChance,
                averageDamage: averageDamage
            )

            errorMessage = nil

        } catch {
            errorMessage = "計算エラー: \(error.localizedDescription)"
            damageResult = nil
        }
    }

    // MARK: - Pokemon Selection

    /// ポケモン一覧を読み込む
    func loadPokemons() async {
        do {
            // 全ポケモンを取得（上限1025）
            let pokemons = try await pokemonRepository.fetchPokemonList(
                limit: 1025,
                offset: 0,
                progressHandler: nil
            )
            availablePokemons = pokemons
        } catch {
            print("Failed to load pokemons: \(error)")
            availablePokemons = []
        }
    }

    // MARK: - Move Selection

    /// 技一覧を読み込む
    func loadMoves() async {
        do {
            let moves = try await moveRepository.fetchAllMoves(versionGroup: nil)
            // ダメージ技のみに絞る（威力があるもの）
            availableMoves = moves.filter { $0.power != nil }
        } catch {
            print("Failed to load moves: \(error)")
            availableMoves = []
        }
    }

    // MARK: - Ability Selection

    /// 特性一覧を読み込む
    func loadAbilities() async {
        do {
            let abilities = try await abilityRepository.fetchAllAbilities()
            availableAbilities = abilities.sorted { $0.nameJa < $1.nameJa }
        } catch {
            print("Failed to load abilities: \(error)")
            availableAbilities = []
        }
    }

    /// 特性を選択（攻撃側）
    func selectAttackerAbility(_ ability: AbilityEntity) {
        battleState.attacker.abilityId = ability.id
    }

    /// 特性を選択（防御側）
    func selectDefenderAbility(_ ability: AbilityEntity) {
        battleState.defender.abilityId = ability.id
    }

    // MARK: - Item Selection

    /// アイテム一覧を読み込む
    func loadItems() async {
        do {
            // held-itemカテゴリーのアイテムを取得
            let items = try await itemProvider.fetchItems(category: "held-item")
            availableItems = items.sorted { $0.nameJa < $1.nameJa }
        } catch {
            print("Failed to load items: \(error)")
            availableItems = []
        }
    }

    /// アイテムを選択（攻撃側）
    func selectAttackerItem(_ item: ItemEntity?) {
        battleState.attacker.heldItemId = item?.id
    }

    /// アイテムを選択（防御側）
    func selectDefenderItem(_ item: ItemEntity?) {
        battleState.defender.heldItemId = item?.id
    }

    // MARK: - Preset Management

    /// プリセット一覧を読み込む
    func loadPresets() async {
        presets = await presetStore.listPresets()
    }

    /// プリセットを保存
    func savePreset(name: String) async throws {
        let preset = BattlePreset(name: name, battleState: battleState)
        try await presetStore.savePreset(preset)
        await loadPresets()
    }

    /// プリセットを読み込む
    func loadPreset(_ preset: BattlePreset) {
        battleState = preset.battleState
        selectedPreset = preset
    }

    /// プリセットを削除
    func deletePreset(_ preset: BattlePreset) async throws {
        try await presetStore.deletePreset(id: preset.id)
        await loadPresets()
        if selectedPreset?.id == preset.id {
            selectedPreset = nil
        }
    }

    /// プリセットを更新
    func updatePreset(_ preset: BattlePreset, name: String) async throws {
        var updated = preset
        updated.update(name: name, battleState: battleState)
        try await presetStore.savePreset(updated)
        await loadPresets()
    }

    // MARK: - Stats Configuration

    /// 努力値を更新（攻撃側）
    func updateAttackerEffortValues(_ evs: EffortValueSet) {
        battleState.attacker.effortValues = evs
    }

    /// 個体値を更新（攻撃側）
    func updateAttackerIndividualValues(_ ivs: IndividualValueSet) {
        battleState.attacker.individualValues = ivs
    }

    /// 性格を更新（攻撃側）
    func updateAttackerNature(_ nature: Nature) {
        battleState.attacker.nature = nature
    }

    /// 努力値を更新（防御側）
    func updateDefenderEffortValues(_ evs: EffortValueSet) {
        battleState.defender.effortValues = evs
    }

    /// 個体値を更新（防御側）
    func updateDefenderIndividualValues(_ ivs: IndividualValueSet) {
        battleState.defender.individualValues = ivs
    }

    /// 性格を更新（防御側）
    func updateDefenderNature(_ nature: Nature) {
        battleState.defender.nature = nature
    }

    // MARK: - Multi-Turn Calculation

    /// ターンを追加
    func addTurn(moveId: Int) {
        battleState.turnMoves.append(moveId)
    }

    /// ターンを削除
    func removeTurn(at index: Int) {
        guard index >= 0 && index < battleState.turnMoves.count else { return }
        battleState.turnMoves.remove(at: index)
    }

    /// ターンの技を更新
    func updateTurnMove(at index: Int, moveId: Int) {
        guard index >= 0 && index < battleState.turnMoves.count else { return }
        battleState.turnMoves[index] = moveId
    }

    /// 全ターンをクリア
    func clearTurns() {
        battleState.turnMoves.removeAll()
        multiTurnResult = nil
    }

    /// 複数ターンのダメージを計算
    func calculateMultiTurnDamage() async {
        guard !battleState.turnMoves.isEmpty else {
            errorMessage = "ターンが設定されていません"
            return
        }

        guard battleState.attacker.pokemonId != nil,
              battleState.defender.pokemonId != nil else {
            errorMessage = "ポケモンを選択してください"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            var turnResults: [TurnDamageResult] = []

            // 各ターンのダメージを計算
            for (index, moveId) in battleState.turnMoves.enumerated() {
                let move = try await moveRepository.fetchMoveDetail(moveId: moveId, versionGroup: nil)
                guard move.power != nil else {
                    errorMessage = "ターン\(index + 1)の技は攻撃技ではありません"
                    return
                }

                // 一時的にselectedMoveIdを設定してcalculateDamage内部のロジックを再利用
                let originalMoveId = battleState.selectedMoveId
                battleState.selectedMoveId = moveId

                // ダメージ計算を実行（内部ロジックを再利用）
                await calculateDamage()

                // 結果を保存
                if let result = damageResult {
                    let turnResult = TurnDamageResult(
                        turnNumber: index + 1,
                        moveId: moveId,
                        moveName: move.nameJa,
                        damageResult: DamageCalculationResult(
                            minDamage: result.minDamage,
                            maxDamage: result.maxDamage,
                            damageRange: result.damageRange,
                            koChance: result.koChance,
                            hitsToKO: result.hitsToKO,
                            defenderMaxHP: result.defenderMaxHP,
                            modifiers: result.modifiers,
                            twoTurnKOChance: result.twoTurnKOChance,
                            averageDamage: result.averageDamage
                        )
                    )
                    turnResults.append(turnResult)
                }

                // selectedMoveIdを元に戻す
                battleState.selectedMoveId = originalMoveId
            }

            // 累積撃破確率を計算
            let defenderMaxHP = turnResults.first?.damageResult.defenderMaxHP ?? 1
            let cumulativeKOProbs = calculateCumulativeKOProbabilities(
                turnResults: turnResults,
                defenderMaxHP: defenderMaxHP
            )

            multiTurnResult = MultiTurnDamageResult(
                turns: turnResults,
                cumulativeKOProbabilities: cumulativeKOProbs,
                defenderMaxHP: defenderMaxHP
            )

            errorMessage = nil

        } catch {
            errorMessage = "計算エラー: \(error.localizedDescription)"
            multiTurnResult = nil
        }
    }

    /// 累積撃破確率を計算
    private func calculateCumulativeKOProbabilities(
        turnResults: [TurnDamageResult],
        defenderMaxHP: Int
    ) -> [Double] {
        var cumulativeProbs: [Double] = []

        for turnNumber in 1...turnResults.count {
            // このターンまでのダメージ範囲の全組み合わせを計算
            let damageRanges = turnResults.prefix(turnNumber).map { $0.damageResult.damageRange }

            // 全組み合わせの累積ダメージを計算
            let allCombinations = cartesianProduct(damageRanges)
            let totalDamages = allCombinations.map { $0.reduce(0, +) }

            // 撃破確率を計算
            let koCount = totalDamages.filter { $0 >= defenderMaxHP }.count
            let koProb = Double(koCount) / Double(totalDamages.count)

            cumulativeProbs.append(koProb)
        }

        return cumulativeProbs
    }

    /// 複数配列のデカルト積を計算
    private func cartesianProduct(_ arrays: [[Int]]) -> [[Int]] {
        guard !arrays.isEmpty else { return [[]] }
        guard arrays.count > 1 else { return arrays[0].map { [$0] } }

        let first = arrays[0]
        let rest = Array(arrays.dropFirst())
        let restProduct = cartesianProduct(rest)

        var result: [[Int]] = []
        for value in first {
            for combination in restProduct {
                result.append([value] + combination)
            }
        }
        return result
    }
}

// MARK: - Damage Result

/// ダメージ計算結果
struct DamageResult: Equatable {
    let minDamage: Int
    let maxDamage: Int
    let damageRange: [Int]
    let koChance: Double
    let hitsToKO: Int
    let defenderMaxHP: Int
    let modifiers: DamageModifiers
    let twoTurnKOChance: Double
    let averageDamage: Double
}
