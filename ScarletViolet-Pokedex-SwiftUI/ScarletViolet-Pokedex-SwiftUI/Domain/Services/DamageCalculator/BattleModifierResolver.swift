//
//  BattleModifierResolver.swift
//  Pokedex
//
//  Created on 2025-11-01.
//

import Foundation

/// バトル補正計算
struct BattleModifierResolver {

    /// 攻撃側のステータス補正倍率を取得（特性によるもの）
    /// - Parameters:
    ///   - abilityId: 特性ID
    ///   - isPhysical: 物理技か
    /// - Returns: 攻撃ステータスの補正倍率
    static func getAttackerStatMultiplier(abilityId: Int?, isPhysical: Bool) -> Double {
        guard let abilityId = abilityId else { return 1.0 }

        switch abilityId {
        // ちからもち: 物理攻撃2倍
        case 37:  // huge-power
            return isPhysical ? 2.0 : 1.0

        // ヨガパワー: 物理攻撃2倍
        case 74:  // pure-power
            return isPhysical ? 2.0 : 1.0

        default:
            return 1.0
        }
    }

    /// 防御側のステータス補正倍率を取得（特性によるもの）
    /// - Parameters:
    ///   - abilityId: 特性ID
    ///   - isPhysical: 物理技か
    /// - Returns: 防御ステータスの補正倍率
    static func getDefenderStatMultiplier(abilityId: Int?, isPhysical: Bool) -> Double {
        guard let abilityId = abilityId else { return 1.0 }

        switch abilityId {
        // ファーコート: 物理防御2倍
        case 169:  // fur-coat
            return isPhysical ? 2.0 : 1.0

        default:
            return 1.0
        }
    }

    /// 補正倍率を計算
    /// - Parameters:
    ///   - battleState: バトル状態
    ///   - moveType: 技のタイプ
    ///   - isPhysical: 物理技か
    ///   - movePower: 技の威力
    ///   - attackerItem: 攻撃側のアイテム
    ///   - typeEffectiveness: タイプ相性倍率（事前計算済み）
    ///   - isSpreadMove: 範囲技か（ダブルバトル用）
    /// - Returns: 補正倍率
    static func resolveModifiers(
        battleState: BattleState,
        moveType: String,
        isPhysical: Bool,
        movePower: Int,
        attackerItem: ItemEntity?,
        typeEffectiveness: Double = 1.0,
        isSpreadMove: Bool = false
    ) -> DamageModifiers {
        let stab = resolveSTAB(
            moveType: moveType,
            attacker: battleState.attacker,
            attackerItem: attackerItem
        )

        let weather = resolveWeatherModifier(
            weather: battleState.environment.weather,
            moveType: moveType
        )

        let terrain = resolveTerrainModifier(
            terrain: battleState.environment.terrain,
            moveType: moveType
        )

        let screen = resolveScreenModifier(
            screen: battleState.environment.screen,
            isPhysical: isPhysical,
            isDouble: battleState.mode == .double
        )

        let item = resolveItemModifier(
            item: attackerItem,
            moveType: moveType,
            attacker: battleState.attacker
        )

        let ability = resolveAbilityModifier(
            attackerAbilityId: battleState.attacker.abilityId,
            defenderAbilityId: battleState.defender.abilityId,
            moveType: moveType,
            movePower: movePower,
            isPhysical: isPhysical,
            typeEffectiveness: typeEffectiveness
        )

        // ダブルバトルの範囲技補正
        let doubleBattleModifier = resolveDoubleBattleModifier(
            mode: battleState.mode,
            isSpreadMove: isSpreadMove
        )

        return DamageModifiers(
            stab: stab,
            typeEffectiveness: typeEffectiveness,
            weather: weather,
            terrain: terrain,
            screen: screen,
            item: item,
            ability: ability,
            other: doubleBattleModifier
        )
    }

    // MARK: - Private Methods

    private static func resolveSTAB(
        moveType: String,
        attacker: BattleParticipantState,
        attackerItem: ItemEntity?
    ) -> Double {
        // オーガポンマスク補正を計算
        let ogerponBonus = resolveOgerponMaskBonus(
            attacker: attacker,
            attackerItem: attackerItem,
            moveType: moveType
        )

        // てきおうりょく（Adaptability）判定
        let hasAdaptability = attacker.abilityId == 91

        return DamageFormulaEngine.calculateSTAB(
            moveType: moveType,
            pokemonTypes: attacker.baseTypes,
            isTerastallized: attacker.isTerastallized,
            teraType: attacker.teraType,
            hasAdaptability: hasAdaptability,
            ogerponMaskBonus: ogerponBonus
        )
    }

    /// オーガポンマスク補正を解決
    /// - Parameters:
    ///   - attacker: 攻撃側の状態
    ///   - attackerItem: 攻撃側のアイテム
    ///   - moveType: 技のタイプ
    /// - Returns: マスク補正倍率（1.0, 1.2, 1.3）
    private static func resolveOgerponMaskBonus(
        attacker: BattleParticipantState,
        attackerItem: ItemEntity?,
        moveType: String
    ) -> Double {
        // アイテムがない場合は補正なし
        guard let item = attackerItem,
              let damageEffect = item.effects?.damageMultiplier else {
            return 1.0
        }

        // オーガポン専用マスクでない場合は補正なし
        guard damageEffect.isOgerponMask else {
            return 1.0
        }

        // ポケモン名チェック（オーガポンかどうか）
        guard let pokemonName = attacker.pokemonName,
              damageEffect.canApply(to: pokemonName) else {
            return 1.0
        }

        // 技タイプがマスクタイプと一致するかチェック
        guard damageEffect.appliesToType(moveType) else {
            return 1.0
        }

        // テラスタル時は1.3倍、通常時は1.2倍
        if attacker.isTerastallized {
            return damageEffect.teraMultiplier ?? damageEffect.baseMultiplier
        } else {
            return damageEffect.baseMultiplier
        }
    }

    private static func resolveWeatherModifier(
        weather: WeatherCondition?,
        moveType: String
    ) -> Double {
        guard let weather = weather else { return 1.0 }

        switch weather {
        case .sun:
            if moveType.lowercased() == "fire" {
                return 1.5
            } else if moveType.lowercased() == "water" {
                return 0.5
            }
        case .rain:
            if moveType.lowercased() == "water" {
                return 1.5
            } else if moveType.lowercased() == "fire" {
                return 0.5
            }
        case .sandstorm, .snow:
            break
        case .none:
            break
        }

        return 1.0
    }

    private static func resolveTerrainModifier(
        terrain: TerrainField?,
        moveType: String
    ) -> Double {
        guard let terrain = terrain else { return 1.0 }

        switch terrain {
        case .electric:
            if moveType.lowercased() == "electric" {
                return 1.3
            }
        case .grassy:
            if moveType.lowercased() == "grass" {
                return 1.3
            }
        case .psychic:
            if moveType.lowercased() == "psychic" {
                return 1.3
            }
        case .misty:
            if moveType.lowercased() == "dragon" {
                return 0.5
            }
        case .none:
            break
        }

        return 1.0
    }

    private static func resolveScreenModifier(
        screen: ScreenEffect?,
        isPhysical: Bool,
        isDouble: Bool
    ) -> Double {
        guard let screen = screen else { return 1.0 }
        return screen.damageReduction(isDouble: isDouble, isPhysical: isPhysical)
    }

    private static func resolveItemModifier(
        item: ItemEntity?,
        moveType: String,
        attacker: BattleParticipantState
    ) -> Double {
        guard let item = item,
              let damageEffect = item.effects?.damageMultiplier else {
            return 1.0
        }

        // 条件チェック
        switch damageEffect.condition {
        case "all_damaging_moves":
            return damageEffect.baseMultiplier

        case "same_type_as_mask":
            // オーガポンマスク
            if let types = damageEffect.types,
               types.contains(where: { $0.lowercased() == moveType.lowercased() }) {
                if attacker.isTerastallized {
                    return damageEffect.teraMultiplier ?? damageEffect.baseMultiplier
                } else {
                    return damageEffect.baseMultiplier
                }
            }

        case "super_effective":
            // TODO: タイプ相性判定が必要
            break

        default:
            break
        }

        return 1.0
    }

    private static func resolveDoubleBattleModifier(
        mode: BattleMode,
        isSpreadMove: Bool
    ) -> Double {
        if mode == .double && isSpreadMove {
            return 0.75  // ダブルバトルの範囲技は0.75倍
        }
        return 1.0
    }

    private static func resolveAbilityModifier(
        attackerAbilityId: Int?,
        defenderAbilityId: Int?,
        moveType: String,
        movePower: Int,
        isPhysical: Bool,
        typeEffectiveness: Double
    ) -> Double {
        var multiplier = 1.0

        // 攻撃側の特性
        if let abilityId = attackerAbilityId {
            multiplier *= resolveAttackerAbility(
                abilityId: abilityId,
                moveType: moveType,
                movePower: movePower,
                isPhysical: isPhysical
            )
        }

        // 防御側の特性
        if let abilityId = defenderAbilityId {
            multiplier *= resolveDefenderAbility(
                abilityId: abilityId,
                moveType: moveType,
                isPhysical: isPhysical,
                typeEffectiveness: typeEffectiveness
            )
        }

        return multiplier
    }

    /// 攻撃側の特性補正を解決
    private static func resolveAttackerAbility(
        abilityId: Int,
        moveType: String,
        movePower: Int,
        isPhysical: Bool
    ) -> Double {
        switch abilityId {
        // テクニシャン: 威力60以下の技が1.5倍
        case 101:  // technician
            return movePower <= 60 ? 1.5 : 1.0

        // てつのこぶし: パンチ技が1.2倍
        case 89:  // iron-fist
            // TODO: 技がパンチ技かどうかの判定が必要
            return 1.0

        // かたいツメ: 接触技が1.3倍
        case 181:  // tough-claws
            // TODO: 技が接触技かどうかの判定が必要
            return 1.0

        // てきおうりょく: タイプ一致時のSTABが2倍（STAB側で処理）
        case 91:  // adaptability
            return 1.0

        // すなのちから: 砂嵐時に岩・地面・鋼タイプの技が1.3倍
        case 159:  // sand-force
            // TODO: 天候情報が必要
            return 1.0

        // ちからずく: 追加効果がある技が1.3倍
        case 125:  // sheer-force
            // TODO: 技の追加効果判定が必要
            return 1.0

        // すてみ: 反動技が1.2倍
        case 120:  // reckless
            // TODO: 技が反動技かどうかの判定が必要
            return 1.0

        // アナライズ: 後攻時に1.3倍
        case 148:  // analytic
            // TODO: 素早さ比較が必要
            return 1.0

        // とうそうしん: 同性なら1.25倍、異性なら0.75倍
        case 79:  // rivalry
            // TODO: 性別情報が必要
            return 1.0

        // サンパワー: 晴れ時に特殊技が1.5倍
        case 94:  // solar-power
            // TODO: 天候情報と物理/特殊判定が必要
            return 1.0

        default:
            return 1.0
        }
    }

    /// 防御側の特性補正を解決
    private static func resolveDefenderAbility(
        abilityId: Int,
        moveType: String,
        isPhysical: Bool,
        typeEffectiveness: Double
    ) -> Double {
        let typeLower = moveType.lowercased()

        switch abilityId {
        // 【無効化系】
        // もらいび: 炎技無効
        case 18:  // flash-fire
            return typeLower == "fire" ? 0.0 : 1.0

        // ちょすい: 水技無効
        case 11:  // water-absorb
            return typeLower == "water" ? 0.0 : 1.0

        // よびみず: 水技無効
        case 114:  // storm-drain
            return typeLower == "water" ? 0.0 : 1.0

        // ひらいしん: 電気技無効
        case 31:  // lightning-rod
            return typeLower == "electric" ? 0.0 : 1.0

        // でんきエンジン: 電気技無効
        case 78:  // motor-drive
            return typeLower == "electric" ? 0.0 : 1.0

        // そうしょく: 草技無効
        case 157:  // sap-sipper
            return typeLower == "grass" ? 0.0 : 1.0

        // ふゆう: 地面技無効
        case 26:  // levitate
            return typeLower == "ground" ? 0.0 : 1.0

        // かんそうはだ: 水技無効、炎技1.25倍
        case 87:  // dry-skin
            if typeLower == "water" {
                return 0.0
            } else if typeLower == "fire" {
                return 1.25
            }
            return 1.0

        // 【軽減系】
        // あついしぼう: 炎・氷タイプの技を0.5倍で受ける
        case 47:  // thick-fat
            if typeLower == "fire" || typeLower == "ice" {
                return 0.5
            }
            return 1.0

        // フィルター/ハードロック/プリズムアーマー: 効果抜群を0.75倍で受ける
        case 111, 116, 230:  // filter, solid-rock, prism-armor
            return typeEffectiveness > 1.0 ? 0.75 : 1.0

        // マルチスケイル/ファントムガード: HP満タン時に0.5倍
        case 136, 231:  // multiscale, shadow-shield
            // TODO: HP判定が必要
            return 1.0

        // もふもふ: 接触技を0.5倍で受ける、炎技は2倍
        case 208:  // fluffy
            if typeLower == "fire" {
                return 2.0
            }
            // TODO: 接触技判定が必要
            return 1.0

        // パンクロック: 音技を0.5倍で受ける
        case 244:  // punk-rock
            // TODO: 音技判定が必要
            return 1.0

        default:
            return 1.0
        }
    }
}
