# パーティ編成機能 設計書

**作成日**: 2025-11-09
**対象バージョン**: ポケモン スカーレット・バイオレット対応版
**アーキテクチャ**: Clean Architecture (SwiftUI + SwiftData)

---

## 📋 要件定義

### 1. 機能概要

ポケモン スカーレット・バイオレット対応のパーティ（最大6匹）を編成・管理する機能を提供します。

### 2. 主要要件

#### 2.1 パーティ編成機能

- 最大6匹のポケモンをパーティに登録
- ポケモンの追加・削除・並び替え
- 各ポケモンの詳細設定：
  - **テラスタイプ選択（18タイプから選択）** ⭐ 最重要
  - フォーム選択（リージョンフォームのみ）
  - 技4つ選択
  - 特性選択
  - 持ち物設定
  - 性格・個体値・努力値設定
  - ニックネーム設定（オプション）
  - レベル設定（1-100）

#### 2.2 パーティ管理機能

- 複数のパーティを保存・管理
- パーティ名称の設定
- パーティの複製・削除
- パーティ一覧表示（テラスタイプ表示含む）

#### 2.3 テラスタル対応機能

- テラスタイプ表示（視覚的にわかりやすく）
- タイプ相性分析でテラスタルを考慮
- テラスタル後のタイプ一致技の確認

#### 2.4 連携機能

- ダメージ計算機へのパーティエクスポート（テラスタル込み）
- 能力値計算機との連携
- ポケモン検索・フィルター機能の活用

### 3. 非機能要件

- SwiftDataでローカル永続化
- 既存のClean Architecture構造に準拠
- iOS 17.0以上対応
- ダークモード対応
- 日本語・英語ローカライゼーション

### 4. スコープ外

- メガシンカ（第6世代）
- ダイマックス（第8世代）
- その他スカーレット・バイオレット以外の要素

---

## 🏗️ アーキテクチャ設計

### 1. レイヤー構成

Clean Architectureの3層構造に従います：

```
┌─────────────────────────────────────┐
│   Presentation Layer (SwiftUI)      │
│   - Views                            │
│   - ViewModels (@MainActor)          │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│   Domain Layer (Pure Swift)          │
│   - Entities                         │
│   - UseCases                         │
│   - Repository Protocols             │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│   Data Layer                         │
│   - SwiftData Models                 │
│   - Repository Implementations       │
│   - Data Mappers                     │
└─────────────────────────────────────┘
```

---

## 📦 Domain Layer 設計

### 1. エンティティ定義

#### 1.1 Party（パーティ全体）

**ファイル**: `Domain/Entities/Party.swift`

```swift
struct Party: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var members: [PartyMember]  // 最大6
    var createdAt: Date
    var updatedAt: Date

    // Computed Properties
    var typeAnalysis: TypeCoverage
    var teraTypeDistribution: [String: Int]  // テラスタイプの分布
    var averageLevel: Double
    var isFull: Bool { members.count == 6 }
}
```

#### 1.2 PartyMember（パーティメンバー）

**ファイル**: `Domain/Entities/PartyMember.swift`

```swift
struct PartyMember: Identifiable, Codable, Hashable {
    let id: UUID
    let pokemonId: Int
    var nickname: String?
    var formId: Int?  // リージョンフォームのみ
    var selectedMoves: [SelectedMove]  // 最大4
    var ability: String
    var item: String?
    var nature: Nature
    var evs: StatValues
    var ivs: StatValues
    var level: Int  // 1-100
    var teraType: String  // ⭐ テラスタイプ（18タイプから選択）
    var position: Int  // 0-5

    // Computed Properties
    var originalTypes: [String]  // 元のタイプ
    var teraTypeMatchesMoves: Bool  // テラスタイプが技と一致するか
    var calculatedStats: StatValues  // 実数値
}
```

#### 1.3 SelectedMove（選択された技）

**ファイル**: `Domain/Entities/PartyMember.swift`

```swift
struct SelectedMove: Codable, Hashable {
    let moveName: String
    let moveType: String  // 技のタイプ
    let slot: Int  // 0-3
    let power: Int?
    let accuracy: Int?
    let pp: Int
}
```

#### 1.4 Nature（性格）

**ファイル**: `Domain/Entities/Nature.swift`

```swift
enum Nature: String, Codable, CaseIterable {
    // 攻撃↑
    case lonely   // 防御↓
    case brave    // 素早さ↓
    case adamant  // 特攻↓
    case naughty  // 特防↓

    // 防御↑
    case bold     // 攻撃↓
    case relaxed  // 素早さ↓
    case impish   // 特攻↓
    case lax      // 特防↓

    // 特攻↑
    case modest   // 攻撃↓
    case mild     // 防御↓
    case quiet    // 素早さ↓
    case rash     // 特防↓

    // 特防↑
    case calm     // 攻撃↓
    case gentle   // 防御↓
    case sassy    // 素早さ↓
    case careful  // 特攻↓

    // 素早さ↑
    case timid    // 攻撃↓
    case hasty    // 防御↓
    case jolly    // 特攻↓
    case naive    // 特防↓

    // 補正なし
    case hardy, docile, serious, bashful, quirky

    var displayName: String { /* ローカライズ */ }
    var displayNameJa: String { /* 日本語名 */ }

    var statModifiers: (increased: StatType?, decreased: StatType?) {
        // 性格補正ロジック
    }
}

enum StatType: String, Codable {
    case attack, defense, specialAttack, specialDefense, speed
}
```

#### 1.5 StatValues（能力値）

**ファイル**: `Domain/Entities/StatValues.swift`

```swift
struct StatValues: Codable, Hashable {
    var hp: Int
    var attack: Int
    var defense: Int
    var specialAttack: Int
    var specialDefense: Int
    var speed: Int

    static var maxEVs: StatValues {
        StatValues(hp: 252, attack: 252, defense: 252,
                  specialAttack: 252, specialDefense: 252, speed: 252)
    }

    static var maxIVs: StatValues {
        StatValues(hp: 31, attack: 31, defense: 31,
                  specialAttack: 31, specialDefense: 31, speed: 31)
    }

    static var zero: StatValues {
        StatValues(hp: 0, attack: 0, defense: 0,
                  specialAttack: 0, specialDefense: 0, speed: 0)
    }

    var total: Int {
        hp + attack + defense + specialAttack + specialDefense + speed
    }
}
```

#### 1.6 TeraType（テラスタイプ）

**ファイル**: `Domain/Entities/TeraType.swift`

```swift
/// スカーレット・バイオレットのテラスタイプ定義
enum TeraType: String, CaseIterable, Codable {
    case normal
    case fire
    case water
    case electric
    case grass
    case ice
    case fighting
    case poison
    case ground
    case flying
    case psychic
    case bug
    case rock
    case ghost
    case dragon
    case dark
    case steel
    case fairy

    /// タイプの日本語名
    var nameJa: String {
        switch self {
        case .normal: return "ノーマル"
        case .fire: return "ほのお"
        case .water: return "みず"
        case .electric: return "でんき"
        case .grass: return "くさ"
        case .ice: return "こおり"
        case .fighting: return "かくとう"
        case .poison: return "どく"
        case .ground: return "じめん"
        case .flying: return "ひこう"
        case .psychic: return "エスパー"
        case .bug: return "むし"
        case .rock: return "いわ"
        case .ghost: return "ゴースト"
        case .dragon: return "ドラゴン"
        case .dark: return "あく"
        case .steel: return "はがね"
        case .fairy: return "フェアリー"
        }
    }

    /// テラスタルのシンボルカラー
    var color: Color {
        // 既存のPokemonTypeColorを活用
        PokemonTypeColor.color(for: self.rawValue)
    }

    /// 全テラスタイプのリスト
    static var allTypes: [String] {
        TeraType.allCases.map { $0.rawValue }
    }
}
```

#### 1.7 TypeCoverage（タイプ相性分析）

**ファイル**: `Domain/Entities/TypeCoverage.swift`

```swift
struct TypeCoverage: Codable, Hashable {
    var weaknesses: [String: Int]    // タイプ: 弱点数
    var resistances: [String: Int]   // タイプ: 耐性数
    var immunities: Set<String>      // 無効タイプ
    var coverageScore: Double        // 攻撃範囲スコア (0.0-1.0)
}
```

### 2. Repository Protocols

#### 2.1 PartyRepositoryProtocol

**ファイル**: `Domain/Interfaces/PartyRepositoryProtocol.swift`

```swift
protocol PartyRepositoryProtocol {
    /// すべてのパーティを取得
    func fetchAllParties() async throws -> [Party]

    /// 特定のパーティを取得
    func fetchParty(id: UUID) async throws -> Party?

    /// パーティを保存（新規/更新）
    func saveParty(_ party: Party) async throws

    /// パーティを削除
    func deleteParty(id: UUID) async throws

    /// パーティを複製
    func duplicateParty(id: UUID) async throws -> Party
}
```

### 3. Use Cases

#### 3.1 FetchPartiesUseCase

**ファイル**: `Domain/UseCases/Party/FetchPartiesUseCase.swift`

```swift
protocol FetchPartiesUseCaseProtocol {
    func execute() async throws -> [Party]
}

final class FetchPartiesUseCase: FetchPartiesUseCaseProtocol {
    private let repository: PartyRepositoryProtocol

    init(repository: PartyRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [Party] {
        try await repository.fetchAllParties()
    }
}
```

#### 3.2 SavePartyUseCase

**ファイル**: `Domain/UseCases/Party/SavePartyUseCase.swift`

```swift
protocol SavePartyUseCaseProtocol {
    func execute(_ party: Party) async throws
}

final class SavePartyUseCase: SavePartyUseCaseProtocol {
    private let repository: PartyRepositoryProtocol

    init(repository: PartyRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ party: Party) async throws {
        var updatedParty = party
        updatedParty.updatedAt = Date()
        try await repository.saveParty(updatedParty)
    }
}
```

#### 3.3 DeletePartyUseCase

**ファイル**: `Domain/UseCases/Party/DeletePartyUseCase.swift`

```swift
protocol DeletePartyUseCaseProtocol {
    func execute(id: UUID) async throws
}

final class DeletePartyUseCase: DeletePartyUseCaseProtocol {
    private let repository: PartyRepositoryProtocol

    init(repository: PartyRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: UUID) async throws {
        try await repository.deleteParty(id: id)
    }
}
```

#### 3.4 AnalyzePartyUseCase

**ファイル**: `Domain/UseCases/Party/AnalyzePartyUseCase.swift`

```swift
protocol AnalyzePartyUseCaseProtocol {
    func execute(_ party: Party) async -> TypeCoverage
}

final class AnalyzePartyUseCase: AnalyzePartyUseCaseProtocol {
    private let typeRepository: TypeRepositoryProtocol

    init(typeRepository: TypeRepositoryProtocol) {
        self.typeRepository = typeRepository
    }

    func execute(_ party: Party) async -> TypeCoverage {
        // タイプ相性分析ロジック
        // 弱点・耐性・無効の集計
        // テラスタル考慮
    }
}
```

---

## 💾 Data Layer 設計

### 1. SwiftData Models

#### 1.1 PartyModel

**ファイル**: `Data/Persistence/PartyModel.swift`

```swift
import Foundation
import SwiftData

@Model
final class PartyModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var members: [PartyMemberModel]
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID, name: String, members: [PartyMemberModel],
         createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.members = members
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

#### 1.2 PartyMemberModel

**ファイル**: `Data/Persistence/PartyMemberModel.swift`

```swift
import Foundation
import SwiftData

@Model
final class PartyMemberModel {
    var id: UUID
    var pokemonId: Int
    var nickname: String?
    var formId: Int?
    var selectedMoves: Data  // JSON encoded [SelectedMove]
    var ability: String
    var item: String?
    var nature: String
    var evs: Data  // JSON encoded StatValues
    var ivs: Data  // JSON encoded StatValues
    var level: Int
    var teraType: String  // ⭐ テラスタイプ
    var position: Int

    init(id: UUID, pokemonId: Int, nickname: String? = nil,
         formId: Int? = nil, selectedMoves: Data, ability: String,
         item: String? = nil, nature: String, evs: Data, ivs: Data,
         level: Int, teraType: String, position: Int) {
        self.id = id
        self.pokemonId = pokemonId
        self.nickname = nickname
        self.formId = formId
        self.selectedMoves = selectedMoves
        self.ability = ability
        self.item = item
        self.nature = nature
        self.evs = evs
        self.ivs = ivs
        self.level = level
        self.teraType = teraType
        self.position = position
    }
}
```

### 2. Repository Implementation

#### 2.1 PartyRepository

**ファイル**: `Data/Repositories/PartyRepository.swift`

```swift
import Foundation
import SwiftData

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
        // 既存チェック
        if let existing = try await fetchParty(id: party.id) {
            // 更新
            let model = PartyMapper.toModel(party)
            modelContext.insert(model)
        } else {
            // 新規
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
            throw PartyError.notFound
        }

        var duplicated = original
        duplicated.id = UUID()
        duplicated.name = "\(original.name) (Copy)"
        duplicated.createdAt = Date()
        duplicated.updatedAt = Date()

        // メンバーのIDも再生成
        duplicated.members = duplicated.members.map { member in
            var newMember = member
            newMember.id = UUID()
            return newMember
        }

        try await saveParty(duplicated)
        return duplicated
    }
}

enum PartyError: Error {
    case notFound
    case invalidData
}
```

### 3. Data Mappers

#### 3.1 PartyMapper

**ファイル**: `Data/DTOs/PartyMapper.swift`

```swift
import Foundation

enum PartyMapper {
    static func toDomain(_ model: PartyModel) -> Party {
        Party(
            id: model.id,
            name: model.name,
            members: model.members.map { PartyMemberMapper.toDomain($0) },
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }

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
```

#### 3.2 PartyMemberMapper

**ファイル**: `Data/DTOs/PartyMemberMapper.swift`

```swift
import Foundation

enum PartyMemberMapper {
    static func toDomain(_ model: PartyMemberModel) -> PartyMember {
        let moves = try? JSONDecoder().decode([SelectedMove].self, from: model.selectedMoves)
        let evs = try? JSONDecoder().decode(StatValues.self, from: model.evs)
        let ivs = try? JSONDecoder().decode(StatValues.self, from: model.ivs)

        return PartyMember(
            id: model.id,
            pokemonId: model.pokemonId,
            nickname: model.nickname,
            formId: model.formId,
            selectedMoves: moves ?? [],
            ability: model.ability,
            item: model.item,
            nature: Nature(rawValue: model.nature) ?? .hardy,
            evs: evs ?? .zero,
            ivs: ivs ?? .maxIVs,
            level: model.level,
            teraType: model.teraType,
            position: model.position
        )
    }

    static func toModel(_ domain: PartyMember) -> PartyMemberModel {
        let movesData = try? JSONEncoder().encode(domain.selectedMoves)
        let evsData = try? JSONEncoder().encode(domain.evs)
        let ivsData = try? JSONEncoder().encode(domain.ivs)

        return PartyMemberModel(
            id: domain.id,
            pokemonId: domain.pokemonId,
            nickname: domain.nickname,
            formId: domain.formId,
            selectedMoves: movesData ?? Data(),
            ability: domain.ability,
            item: domain.item,
            nature: domain.nature.rawValue,
            evs: evsData ?? Data(),
            ivs: ivsData ?? Data(),
            level: domain.level,
            teraType: domain.teraType,
            position: domain.position
        )
    }
}
```

---

## 🎨 Presentation Layer 設計

### 1. 画面構成

```
PartyListView (パーティ一覧)
    ├─ PartyCardView (各パーティカード)
    │   ├─ パーティ名
    │   ├─ メンバー表示（アイコン + テラスタイプバッジ × 6）
    │   └─ タップ → PartyFormationView（編集）
    └─ FloatingActionButton: 新規作成
        ↓
PartyFormationView (パーティ編成画面)
    ├─ NavigationBar
    │   ├─ Title: パーティ名編集可能
    │   └─ Toolbar
    │       ├─ キャンセル
    │       └─ 保存
    ├─ PartyMemberSlotView × 6
    │   ├─ ポケモンアイコン
    │   ├─ テラスタイプバッジ ⭐
    │   ├─ レベル表示
    │   └─ タップ → PokemonSelectorView
    ├─ TypeAnalysisView (タイプ相性分析 + テラスタル分析)
    └─ DeleteButton（既存パーティの場合）
        ↓
PartyMemberEditorView (個別ポケモン設定)
    ├─ NavigationBar: "ポケモン名"
    ├─ ScrollView
    │   ├─ PokemonInfoSection
    │   │   ├─ スプライト画像
    │   │   ├─ ニックネーム入力
    │   │   └─ レベル選択（1-100）
    │   ├─ TeraTypePicker ⭐ (18タイプからピッカー)
    │   ├─ FormPicker（リージョンフォームがある場合のみ）
    │   ├─ AbilityPicker
    │   ├─ ItemPicker
    │   ├─ NaturePicker
    │   ├─ MoveSelectorView × 4
    │   └─ StatsConfigView (努力値/個体値)
    └─ Toolbar: 完了
```

### 2. ViewModels

#### 2.1 PartyListViewModel

**ファイル**: `Presentation/PartyFormation/PartyListViewModel.swift`

```swift
import Foundation
import Combine

@MainActor
final class PartyListViewModel: ObservableObject {
    // Published State
    @Published var parties: [Party] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingDeleteConfirmation: Bool = false
    @Published var partyToDelete: Party?

    // Dependencies
    private let fetchPartiesUseCase: FetchPartiesUseCaseProtocol
    private let deletePartyUseCase: DeletePartyUseCaseProtocol

    init(fetchPartiesUseCase: FetchPartiesUseCaseProtocol,
         deletePartyUseCase: DeletePartyUseCaseProtocol) {
        self.fetchPartiesUseCase = fetchPartiesUseCase
        self.deletePartyUseCase = deletePartyUseCase
    }

    func loadParties() async {
        isLoading = true
        defer { isLoading = false }

        do {
            parties = try await fetchPartiesUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteParty(_ party: Party) async {
        do {
            try await deletePartyUseCase.execute(id: party.id)
            await loadParties()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmDelete(_ party: Party) {
        partyToDelete = party
        showingDeleteConfirmation = true
    }
}
```

#### 2.2 PartyFormationViewModel

**ファイル**: `Presentation/PartyFormation/PartyFormationViewModel.swift`

```swift
import Foundation
import Combine

@MainActor
final class PartyFormationViewModel: ObservableObject {
    // Published State
    @Published var party: Party
    @Published var isEditing: Bool = false
    @Published var selectedMemberIndex: Int?
    @Published var typeAnalysis: TypeCoverage?
    @Published var errorMessage: String?
    @Published var showingPokemonSelector: Bool = false
    @Published var showingMemberEditor: Bool = false

    // Dependencies
    private let savePartyUseCase: SavePartyUseCaseProtocol
    private let analyzePartyUseCase: AnalyzePartyUseCaseProtocol
    private let pokemonRepository: PokemonRepositoryProtocol

    init(party: Party? = nil,
         savePartyUseCase: SavePartyUseCaseProtocol,
         analyzePartyUseCase: AnalyzePartyUseCaseProtocol,
         pokemonRepository: PokemonRepositoryProtocol) {
        self.party = party ?? Party.empty
        self.savePartyUseCase = savePartyUseCase
        self.analyzePartyUseCase = analyzePartyUseCase
        self.pokemonRepository = pokemonRepository
    }

    func addPokemon(_ pokemon: Pokemon, at index: Int) {
        let member = PartyMember(
            id: UUID(),
            pokemonId: pokemon.id,
            nickname: nil,
            formId: nil,
            selectedMoves: [],
            ability: pokemon.abilities.first?.name ?? "",
            item: nil,
            nature: .hardy,
            evs: .zero,
            ivs: .maxIVs,
            level: 50,
            teraType: pokemon.types.first?.name ?? "normal",
            position: index
        )

        if index < party.members.count {
            party.members[index] = member
        } else {
            party.members.append(member)
        }

        Task { await analyzeTypeMatchups() }
    }

    func removePokemon(at index: Int) {
        guard index < party.members.count else { return }
        party.members.remove(at: index)
        Task { await analyzeTypeMatchups() }
    }

    func movePokemon(from source: Int, to destination: Int) {
        party.members.move(fromOffsets: IndexSet(integer: source),
                          toOffset: destination)
        // 位置を再計算
        for (index, _) in party.members.enumerated() {
            party.members[index].position = index
        }
    }

    func saveParty() async throws {
        party.updatedAt = Date()
        try await savePartyUseCase.execute(party)
    }

    func analyzeTypeMatchups() async {
        typeAnalysis = await analyzePartyUseCase.execute(party)
    }

    func selectMember(at index: Int) {
        selectedMemberIndex = index
        showingMemberEditor = true
    }
}
```

#### 2.3 PartyMemberEditorViewModel

**ファイル**: `Presentation/PartyFormation/PartyMemberEditorViewModel.swift`

```swift
import Foundation
import Combine

@MainActor
final class PartyMemberEditorViewModel: ObservableObject {
    // Published State
    @Published var member: PartyMember
    @Published var pokemon: Pokemon?
    @Published var availableForms: [PokemonForm] = []
    @Published var availableMoves: [Move] = []
    @Published var selectedForm: PokemonForm?

    // Dependencies
    private let pokemonRepository: PokemonRepositoryProtocol
    private let moveRepository: MoveRepositoryProtocol

    init(member: PartyMember,
         pokemonRepository: PokemonRepositoryProtocol,
         moveRepository: MoveRepositoryProtocol) {
        self.member = member
        self.pokemonRepository = pokemonRepository
        self.moveRepository = moveRepository
    }

    func loadPokemonData() async {
        do {
            pokemon = try await pokemonRepository.fetchPokemonDetail(id: member.pokemonId)
            if let pokemon = pokemon {
                availableForms = try await pokemonRepository.fetchPokemonForms(pokemonId: pokemon.id)
                availableMoves = pokemon.moves.compactMap { /* Move取得 */ }
            }
        } catch {
            // エラー処理
        }
    }

    func updateTeraType(_ type: String) {
        member.teraType = type
    }

    func updateMove(_ move: SelectedMove, at slot: Int) {
        if slot < member.selectedMoves.count {
            member.selectedMoves[slot] = move
        } else {
            member.selectedMoves.append(move)
        }
    }
}
```

### 3. Views

#### 3.1 PartyListView

**ファイル**: `Presentation/PartyFormation/PartyListView.swift`

```swift
import SwiftUI

struct PartyListView: View {
    @StateObject var viewModel: PartyListViewModel
    @State private var showingNewPartySheet = false

    var body: some View {
        ZStack {
            if viewModel.parties.isEmpty {
                EmptyPartyView {
                    showingNewPartySheet = true
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.parties) { party in
                            NavigationLink(destination: PartyFormationView(party: party)) {
                                PartyCardView(party: party)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.confirmDelete(party)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }

            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showingNewPartySheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Parties")
        .sheet(isPresented: $showingNewPartySheet) {
            PartyFormationView(party: nil)
        }
        .confirmationDialog(
            "Delete Party?",
            isPresented: $viewModel.showingDeleteConfirmation,
            presenting: viewModel.partyToDelete
        ) { party in
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteParty(party)
                }
            }
        }
        .task {
            await viewModel.loadParties()
        }
    }
}
```

#### 3.2 PartyCardView

**ファイル**: `Presentation/PartyFormation/Components/PartyCardView.swift`

```swift
import SwiftUI

struct PartyCardView: View {
    let party: Party

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                Text(party.name)
                    .font(.headline)
                Spacer()
                Text(party.updatedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // メンバー表示
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: 8)
            ], spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    if index < party.members.count {
                        PartyMemberThumbnail(member: party.members[index])
                    } else {
                        EmptySlotView()
                    }
                }
            }

            // 統計情報
            HStack {
                Label("\(party.members.count)/6", systemImage: "person.3.fill")
                    .font(.caption)
                Spacer()
                if let analysis = party.typeAnalysis {
                    Text("Coverage: \(Int(analysis.coverageScore * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PartyMemberThumbnail: View {
    let member: PartyMember

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                // ポケモンアイコン
                AsyncImage(url: URL(string: member.spriteURL ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 60, height: 60)
                .background(Color(.systemGray6))
                .cornerRadius(8)

                // テラスタイプバッジ
                TeraTypeBadge(teraType: member.teraType)
                    .offset(x: 4, y: 4)
            }

            Text("Lv.\(member.level)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct EmptySlotView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundColor(.secondary.opacity(0.3))
            .frame(width: 60, height: 60)
    }
}
```

#### 3.3 TeraTypePicker

**ファイル**: `Presentation/PartyFormation/Components/TeraTypePicker.swift`

```swift
import SwiftUI

struct TeraTypePicker: View {
    @Binding var selectedTeraType: String
    let pokemonTypes: [String]  // 元のタイプ

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tera Type")
                .font(.headline)

            // テラスタルクリスタルのようなビジュアル
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 70), spacing: 12)
            ], spacing: 12) {
                ForEach(TeraType.allCases, id: \.self) { type in
                    TeraTypeButton(
                        teraType: type,
                        isSelected: selectedTeraType == type.rawValue,
                        isPokemonOriginalType: pokemonTypes.contains(type.rawValue)
                    ) {
                        selectedTeraType = type.rawValue
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TeraTypeButton: View {
    let teraType: TeraType
    let isSelected: Bool
    let isPokemonOriginalType: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(teraType.color.opacity(0.2))
                        .frame(width: 56, height: 56)

                    // テラスタルクリスタル風のアイコン
                    Image(systemName: "diamond.fill")
                        .foregroundColor(teraType.color)
                        .font(.title2)

                    // オリジナルタイプマーカー
                    if isPokemonOriginalType {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                            .offset(x: 18, y: -18)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )

                Text(teraType.nameJa)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}
```

#### 3.4 TeraTypeBadge

**ファイル**: `Presentation/PartyFormation/Components/TeraTypeBadge.swift`

```swift
import SwiftUI

/// パーティスロットに表示する小さなテラスタイプバッジ
struct TeraTypeBadge: View {
    let teraType: String
    let size: CGFloat = 24

    private var typeEnum: TeraType? {
        TeraType(rawValue: teraType)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(typeEnum?.color.opacity(0.3) ?? Color.gray.opacity(0.3))
                .frame(width: size, height: size)

            Image(systemName: "diamond.fill")
                .font(.system(size: size * 0.5))
                .foregroundColor(typeEnum?.color ?? .gray)
        }
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(radius: 2)
    }
}
```

---

## 🔌 DIContainer 統合

**ファイル**: `Application/DIContainer.swift` (拡張)

```swift
extension DIContainer {
    // MARK: - Party Repository
    private var partyRepository: PartyRepositoryProtocol {
        if _partyRepository == nil {
            guard let modelContext = modelContext else {
                fatalError("ModelContext not initialized")
            }
            _partyRepository = PartyRepository(modelContext: modelContext)
        }
        return _partyRepository!
    }

    // MARK: - Party UseCases
    func makeFetchPartiesUseCase() -> FetchPartiesUseCaseProtocol {
        FetchPartiesUseCase(repository: partyRepository)
    }

    func makeSavePartyUseCase() -> SavePartyUseCaseProtocol {
        SavePartyUseCase(repository: partyRepository)
    }

    func makeDeletePartyUseCase() -> DeletePartyUseCaseProtocol {
        DeletePartyUseCase(repository: partyRepository)
    }

    func makeAnalyzePartyUseCase() -> AnalyzePartyUseCaseProtocol {
        AnalyzePartyUseCase(typeRepository: typeRepository)
    }

    // MARK: - Party ViewModels
    func makePartyListViewModel() -> PartyListViewModel {
        PartyListViewModel(
            fetchPartiesUseCase: makeFetchPartiesUseCase(),
            deletePartyUseCase: makeDeletePartyUseCase()
        )
    }

    func makePartyFormationViewModel(party: Party? = nil) -> PartyFormationViewModel {
        PartyFormationViewModel(
            party: party,
            savePartyUseCase: makeSavePartyUseCase(),
            analyzePartyUseCase: makeAnalyzePartyUseCase(),
            pokemonRepository: pokemonRepository
        )
    }

    func makePartyMemberEditorViewModel(member: PartyMember) -> PartyMemberEditorViewModel {
        PartyMemberEditorViewModel(
            member: member,
            pokemonRepository: pokemonRepository,
            moveRepository: moveRepository
        )
    }
}
```

---

## 📱 アプリ統合

**ファイル**: `PokedexApp.swift` (修正)

```swift
import SwiftUI
import SwiftData

@main
struct PokedexApp: App {
    @StateObject private var container = DIContainer.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
        }
        .modelContainer(container.modelContainer)
    }
}

struct ContentView: View {
    @EnvironmentObject var container: DIContainer

    var body: some View {
        TabView {
            // 既存タブ
            NavigationStack {
                PokemonListView(viewModel: container.makePokemonListViewModel())
            }
            .tabItem {
                Label("Pokédex", systemImage: "book.fill")
            }

            NavigationStack {
                StatsCalculatorView(viewModel: container.makeStatsCalculatorViewModel())
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                DamageCalculatorView(store: container.makeDamageCalculatorStore())
            }
            .tabItem {
                Label("Damage", systemImage: "bolt.fill")
            }

            // ⭐ 新規: パーティ編成タブ
            NavigationStack {
                PartyListView(viewModel: container.makePartyListViewModel())
            }
            .tabItem {
                Label("Party", systemImage: "person.3.fill")
            }
        }
    }
}
```

---

## 📂 ファイル構成

```
ScarletViolet-Pokedex-SwiftUI/
├── Application/
│   └── DIContainer.swift                    [修正] パーティ関連の依存注入追加
│
├── Domain/
│   ├── Entities/
│   │   ├── Party.swift                      [新規] パーティエンティティ
│   │   ├── PartyMember.swift                [新規] パーティメンバー
│   │   ├── Nature.swift                     [新規] 性格enum
│   │   ├── StatValues.swift                 [新規] 能力値構造体
│   │   ├── TeraType.swift                   [新規] テラスタイプenum
│   │   └── TypeCoverage.swift               [新規] タイプ相性分析
│   │
│   ├── Interfaces/
│   │   └── PartyRepositoryProtocol.swift    [新規] パーティリポジトリIF
│   │
│   └── UseCases/
│       └── Party/                           [新規ディレクトリ]
│           ├── FetchPartiesUseCase.swift    [新規]
│           ├── SavePartyUseCase.swift       [新規]
│           ├── DeletePartyUseCase.swift     [新規]
│           └── AnalyzePartyUseCase.swift    [新規]
│
├── Data/
│   ├── Persistence/
│   │   ├── PartyModel.swift                 [新規] SwiftDataモデル
│   │   └── PartyMemberModel.swift           [新規] SwiftDataモデル
│   │
│   ├── DTOs/
│   │   ├── PartyMapper.swift                [新規] ドメイン⇔データ変換
│   │   └── PartyMemberMapper.swift          [新規] ドメイン⇔データ変換
│   │
│   └── Repositories/
│       └── PartyRepository.swift            [新規] パーティリポジトリ実装
│
└── Presentation/
    ├── PartyFormation/                      [新規ディレクトリ]
    │   ├── PartyListView.swift              [新規] 一覧画面
    │   ├── PartyListViewModel.swift         [新規] 一覧VM
    │   ├── PartyFormationView.swift         [新規] 編成画面
    │   ├── PartyFormationViewModel.swift    [新規] 編成VM
    │   ├── PartyMemberEditorView.swift      [新規] 個別設定画面
    │   ├── PartyMemberEditorViewModel.swift [新規] 個別設定VM
    │   │
    │   └── Components/                      [新規ディレクトリ]
    │       ├── PartyCardView.swift          [新規] パーティカード
    │       ├── PartyMemberSlotView.swift    [新規] メンバースロット
    │       ├── TeraTypePicker.swift         [新規] テラスタイプ選択UI
    │       ├── TeraTypeBadge.swift          [新規] テラスタイプバッジ
    │       ├── TypeAnalysisView.swift       [新規] タイプ相性分析表示
    │       ├── MoveSelectorView.swift       [新規] 技選択UI
    │       ├── StatsConfigView.swift        [新規] 能力値設定UI
    │       ├── NaturePicker.swift           [新規] 性格選択UI
    │       └── PokemonSelectorSheet.swift   [新規] ポケモン選択シート
    │
    └── PokedexApp.swift                     [修正] 新規タブ追加
```

---

## 📊 実装計画

### Phase 1: Domain Layer（コアロジック）

1. ✅ `TeraType` enum定義
2. ✅ `Nature` enum定義
3. ✅ `StatValues` 構造体
4. ✅ `Party` エンティティ
5. ✅ `PartyMember` エンティティ
6. ✅ `TypeCoverage` 構造体
7. ✅ `PartyRepositoryProtocol` インターフェース
8. ✅ UseCases実装（5ファイル）

### Phase 2: Data Layer（永続化）

9. ✅ `PartyModel` SwiftDataモデル
10. ✅ `PartyMemberModel` SwiftDataモデル
11. ✅ `PartyMapper` 実装
12. ✅ `PartyMemberMapper` 実装
13. ✅ `PartyRepository` 実装

### Phase 3: Presentation Layer - 基本UI

14. ✅ `PartyListView` + ViewModel
15. ✅ `PartyCardView` コンポーネント
16. ✅ `PartyFormationView` + ViewModel
17. ✅ `PartyMemberSlotView` コンポーネント

### Phase 4: Presentation Layer - テラスタル UI

18. ✅ `TeraTypePicker` コンポーネント
19. ✅ `TeraTypeBadge` コンポーネント
20. ✅ `TypeAnalysisView` コンポーネント

### Phase 5: Presentation Layer - 詳細設定

21. ✅ `PartyMemberEditorView` + ViewModel
22. ✅ `MoveSelectorView` コンポーネント
23. ✅ `StatsConfigView` コンポーネント
24. ✅ `NaturePicker` コンポーネント
25. ✅ `PokemonSelectorSheet` コンポーネント

### Phase 6: 連携機能

26. ✅ タイプ相性分析ロジック
27. ✅ ダメージ計算機連携
28. ✅ DIContainer統合

### Phase 7: 仕上げ

29. ✅ エラーハンドリング
30. ✅ ローカライゼーション（日本語/英語）
31. ✅ UI/UX改善
32. ✅ テスト

---

## 🎯 主要機能の実装詳細

### 1. テラスタイプ選択システム

**仕様:**
- 18タイプから1つ選択
- 元のタイプには星マーク表示
- クリスタル風のビジュアルデザイン

### 2. タイプ相性分析

**分析項目:**
- パーティ全体の弱点集計
- パーティ全体の耐性集計
- 攻撃範囲カバレッジスコア
- テラスタル考慮の分析

### 3. 能力値計算

**計算式:**
```
実数値 = floor((種族値 × 2 + 個体値 + floor(努力値 / 4)) × レベル / 100) + レベル + 10
※ HP以外は性格補正も適用
```

### 4. データ永続化

**SwiftData戦略:**
- `PartyModel` と `PartyMemberModel` を `@Model` として定義
- JSON Encodingで複雑なデータ（技、能力値）をData型で保存
- 更新時は `updatedAt` を自動更新

---

## 🔄 将来の拡張可能性

### 短期

- [ ] パーティのインポート/エクスポート（JSON形式）
- [ ] ShowdownやPorybox形式のインポート対応
- [ ] パーティのQRコード生成

### 中期

- [ ] タイプ相性のビジュアル化（ヒートマップ）
- [ ] パーティ同士の対戦シミュレーション
- [ ] 技範囲の可視化

### 長期

- [ ] オンラインバックアップ
- [ ] パーティの共有機能
- [ ] AI によるパーティ提案

---

## ✅ チェックリスト

- [x] 要件定義完了
- [x] ドメイン設計完了
- [x] データ永続化設計完了
- [x] UI設計完了
- [x] ファイル構成定義完了
- [ ] 実装開始準備完了

---

**最終更新**: 2025-11-09
**レビュアー**: -
**承認**: -
