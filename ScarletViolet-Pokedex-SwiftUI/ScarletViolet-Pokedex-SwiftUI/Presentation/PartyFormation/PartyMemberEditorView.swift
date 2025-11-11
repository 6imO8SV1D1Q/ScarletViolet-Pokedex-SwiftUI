//
//  PartyMemberEditorView.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Party member detailed editor
//
//  Created by Claude on 2025-11-09.
//

import SwiftUI

struct PartyMemberEditorView: View {
    @ObservedObject var viewModel: PartyMemberEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var member: PartyMember
    @State private var showingMoveSelector = false
    @State private var selectedMoveSlot: Int?
    @State private var showingEVEditor = false

    var body: some View {
        Form {
            // Basic Info
            Section("Basic Info") {
                if let pokemon = viewModel.pokemon {
                    HStack {
                        Text("Pokemon")
                        Spacer()
                        Text(pokemon.displayName)
                            .foregroundColor(.secondary)
                    }
                }

                TextField("Nickname (Optional)", text: Binding(
                    get: { viewModel.member.nickname ?? "" },
                    set: { viewModel.member.nickname = $0.isEmpty ? nil : $0 }
                ))

                Stepper("Level: \(viewModel.member.level)", value: $viewModel.member.level, in: 1...100)
            }

            // Tera Type
            Section {
                if let pokemon = viewModel.pokemon {
                    TeraTypePicker(
                        selectedTeraType: Binding(
                            get: { viewModel.member.teraType },
                            set: { viewModel.updateTeraType($0) }
                        ),
                        pokemonTypes: pokemon.types.map { $0.name }
                    )
                }
            } header: {
                Text("Tera Type")
            }

            // Nature
            Section("Nature") {
                Picker("Nature", selection: $viewModel.member.nature) {
                    ForEach(Nature.allCases, id: \.self) { nature in
                        Text(nature.displayName).tag(nature)
                    }
                }
            }

            // Ability
            Section("Ability") {
                if let pokemon = viewModel.pokemon {
                    Picker("Ability", selection: $viewModel.member.ability) {
                        ForEach(pokemon.abilities, id: \.name) { ability in
                            Text(ability.displayName).tag(ability.name)
                        }
                    }
                }
            }

            // Stats (EVs/IVs)
            Section("Stats") {
                Button {
                    showingEVEditor = true
                } label: {
                    HStack {
                        Text("EVs")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(viewModel.member.evs.total)/510")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("IVs")
                    Spacer()
                    Text("\(viewModel.member.ivs.total)/186")
                        .foregroundColor(.secondary)
                }
            }

            // Moves
            Section("Moves") {
                ForEach(0..<4, id: \.self) { slot in
                    Button {
                        selectedMoveSlot = slot
                        showingMoveSelector = true
                    } label: {
                        HStack {
                            Text("Move \(slot + 1)")
                                .foregroundColor(.primary)
                            Spacer()
                            if slot < viewModel.member.selectedMoves.count {
                                Text(viewModel.member.selectedMoves[slot].moveName)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Empty")
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Member")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    member = viewModel.member
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingMoveSelector) {
            if let slot = selectedMoveSlot {
                PartyMoveSelectorSheet(
                    availableMoves: viewModel.availableMoves,
                    selectedMoveSlot: slot,
                    onMoveSelected: { move in
                        let selectedMove = SelectedMove(
                            moveName: move.name,
                            moveType: move.type.name,
                            slot: slot,
                            power: move.power,
                            accuracy: move.accuracy,
                            pp: move.pp ?? 5
                        )
                        viewModel.updateMove(selectedMove, at: slot)
                        showingMoveSelector = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingEVEditor) {
            EVEditorSheet(evs: $viewModel.member.evs)
        }
        .task {
            await viewModel.loadPokemonData()
        }
    }
}

// MARK: - Party Move Selector Sheet

struct PartyMoveSelectorSheet: View {
    let availableMoves: [MoveEntity]
    let selectedMoveSlot: Int
    let onMoveSelected: (MoveEntity) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredMoves: [MoveEntity] {
        if searchText.isEmpty {
            return availableMoves
        }
        return availableMoves.filter { move in
            move.nameJa.localizedCaseInsensitiveContains(searchText) ||
            move.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredMoves) { move in
                Button {
                    onMoveSelected(move)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(move.nameJa)
                                .font(.body)
                            Spacer()
                            Text(move.type.nameJa ?? move.type.japaneseName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(move.type.color)
                                .foregroundColor(move.type.textColor)
                                .cornerRadius(4)
                        }

                        HStack(spacing: 12) {
                            if let power = move.power {
                                Text("威力: \(power)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let accuracy = move.accuracy {
                                Text("命中: \(accuracy)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let pp = move.pp {
                                Text("PP: \(pp)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .searchable(text: $searchText, prompt: "技を検索")
            .navigationTitle("Move \(selectedMoveSlot + 1) を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - EV Editor Sheet

struct EVEditorSheet: View {
    @Binding var evs: StatValues
    @Environment(\.dismiss) private var dismiss

    var remainingEVs: Int {
        510 - evs.total
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("残り: \(remainingEVs)")
                        .font(.headline)
                        .foregroundColor(remainingEVs >= 0 ? .primary : .red)
                } header: {
                    Text("努力値 (\(evs.total)/510)")
                }

                Section {
                    EVStatRow(label: "HP", value: $evs.hp, remaining: remainingEVs)
                    EVStatRow(label: "攻撃", value: $evs.attack, remaining: remainingEVs)
                    EVStatRow(label: "防御", value: $evs.defense, remaining: remainingEVs)
                    EVStatRow(label: "特攻", value: $evs.specialAttack, remaining: remainingEVs)
                    EVStatRow(label: "特防", value: $evs.specialDefense, remaining: remainingEVs)
                    EVStatRow(label: "素早さ", value: $evs.speed, remaining: remainingEVs)
                }

                Section {
                    Button("すべてリセット") {
                        evs = StatValues(
                            hp: 0,
                            attack: 0,
                            defense: 0,
                            specialAttack: 0,
                            specialDefense: 0,
                            speed: 0
                        )
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("努力値を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                    .disabled(remainingEVs < 0)
                }
            }
        }
    }
}

// MARK: - EV Stat Row

struct EVStatRow: View {
    let label: String
    @Binding var value: Int
    let remaining: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.body)
                Spacer()
                Text("\(value)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    if value >= 10 {
                        value -= 10
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                }
                .disabled(value == 0)

                Slider(value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ), in: 0...252, step: 4)

                Button {
                    if value + 10 <= 252 && remaining >= 10 {
                        value += 10
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .disabled(value >= 252 || remaining < 10)
            }
        }
    }
}
