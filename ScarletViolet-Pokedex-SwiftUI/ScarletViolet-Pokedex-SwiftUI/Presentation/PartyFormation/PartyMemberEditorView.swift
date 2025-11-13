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
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Binding var member: PartyMember
    @State private var showingMoveSelector = false
    @State private var selectedMoveSlot: Int?
    @State private var showingEVEditor = false
    @State private var showingIVEditor = false

    var body: some View {
        Form {
            // Basic Info
            Section(NSLocalizedString("party.basic_info", comment: "")) {
                if let pokemon = viewModel.pokemon {
                    HStack {
                        Text(NSLocalizedString("party.pokemon", comment: ""))
                        Spacer()
                        Text(pokemon.displayName)
                            .foregroundColor(.secondary)
                    }
                }

                TextField(NSLocalizedString("party.nickname", comment: ""), text: Binding(
                    get: { viewModel.member.nickname ?? "" },
                    set: { viewModel.member.nickname = $0.isEmpty ? nil : $0 }
                ))

                Stepper(String(format: NSLocalizedString("party.level", comment: ""), viewModel.member.level), value: $viewModel.member.level, in: 1...100)
            }

            // Tera Type
            Section {
                TeraTypePicker(
                    selectedTeraType: Binding(
                        get: { viewModel.member.teraType },
                        set: { viewModel.updateTeraType($0) }
                    )
                )
            } header: {
                Text(NSLocalizedString("party.tera_type", comment: ""))
            }

            // Nature
            Section(NSLocalizedString("party.nature", comment: "")) {
                Picker(NSLocalizedString("party.nature", comment: ""), selection: $viewModel.member.nature) {
                    ForEach(Nature.allCases, id: \.self) { nature in
                        Text(nature.displayName).tag(nature)
                    }
                }
                .pickerStyle(.menu)
            }

            // Ability
            Section(NSLocalizedString("party.ability", comment: "")) {
                if let pokemon = viewModel.pokemon {
                    Picker(NSLocalizedString("party.ability", comment: ""), selection: $viewModel.member.ability) {
                        ForEach(pokemon.abilities, id: \.name) { ability in
                            Text(ability.displayName).tag(ability.name)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // Held Item
            Section {
                Picker(NSLocalizedString("party.held_item", comment: ""), selection: Binding(
                    get: { viewModel.member.item ?? "" },
                    set: { newValue in
                        viewModel.member.item = newValue.isEmpty ? nil : newValue
                    }
                )) {
                    Text(NSLocalizedString("party.item_none", comment: "")).tag("")
                    ForEach(viewModel.availableItems, id: \.id) { item in
                        Text(item.nameJa).tag(item.name)
                    }
                }
                .pickerStyle(.navigationLink)

                // Show item description if selected
                if let itemName = viewModel.member.item,
                   let selectedItem = viewModel.availableItems.first(where: { $0.name == itemName }) {
                    Text(selectedItem.descriptionJa ?? selectedItem.description ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(NSLocalizedString("party.held_item", comment: "") + " (\(viewModel.availableItems.count))")
            }

            // Stats (EVs/IVs)
            Section(NSLocalizedString("party.stats", comment: "")) {
                Button {
                    showingEVEditor = true
                } label: {
                    HStack {
                        Text(NSLocalizedString("party.evs", comment: ""))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(viewModel.member.evs.total)/510")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    showingIVEditor = true
                } label: {
                    HStack {
                        Text(NSLocalizedString("party.ivs", comment: ""))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(viewModel.member.ivs.total)/186")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Moves
            Section {
                ForEach(0..<4, id: \.self) { slot in
                    Button {
                        selectedMoveSlot = slot
                        showingMoveSelector = true
                    } label: {
                        if slot < viewModel.member.selectedMoves.count {
                            // Show move details when selected
                            let move = viewModel.member.selectedMoves[slot]
                            let moveType = PokemonType(slot: 1, name: move.moveType, nameJa: nil)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    // Display move name from availableMoves if possible, otherwise use stored name
                                    let displayName: String = {
                                        if let moveEntity = viewModel.availableMoves.first(where: { $0.name == move.moveName }) {
                                            return moveEntity.nameJa
                                        }
                                        return move.moveName
                                    }()
                                    Text(displayName)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    // Type badge
                                    Text(moveType.nameJa ?? moveType.japaneseName)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(moveType.color)
                                        .foregroundColor(moveType.textColor)
                                        .cornerRadius(4)
                                }

                                // Power, Accuracy, PP
                                HStack(spacing: 12) {
                                    if let power = move.power {
                                        Text(NSLocalizedString("move.power_label", comment: "") + " \(power)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    if let accuracy = move.accuracy {
                                        Text(NSLocalizedString("move.accuracy_label", comment: "") + " \(accuracy)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text("PP: \(move.pp)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        } else {
                            // Empty slot
                            HStack {
                                Text(String(format: NSLocalizedString("party.move_slot", comment: ""), slot + 1))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(NSLocalizedString("party.empty_move", comment: ""))
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text(NSLocalizedString("party.moves", comment: "") + " (\(viewModel.availableMoves.count))")
            }

            // Notes
            Section(NSLocalizedString("party.notes", comment: "")) {
                TextEditor(text: Binding(
                    get: { viewModel.member.notes ?? "" },
                    set: { viewModel.member.notes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 100)
            }
        }
        .navigationTitle(NSLocalizedString("party.edit_member_title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(NSLocalizedString("common.done", comment: "")) {
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
                .environmentObject(localizationManager)
            }
        }
        .sheet(isPresented: $showingEVEditor) {
            EVEditorSheet(evs: $viewModel.member.evs)
        }
        .sheet(isPresented: $showingIVEditor) {
            IVEditorSheet(ivs: $viewModel.member.ivs)
        }
        .task {
            await viewModel.loadPokemonData()
            await viewModel.loadAvailableItems()
        }
    }
}

// MARK: - Party Move Selector Sheet

struct PartyMoveSelectorSheet: View {
    let availableMoves: [MoveEntity]
    let selectedMoveSlot: Int
    let onMoveSelected: (MoveEntity) -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
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
            Group {
                if filteredMoves.isEmpty {
                    VStack(spacing: 16) {
                        if availableMoves.isEmpty {
                            ProgressView()
                            Text(NSLocalizedString("party.moves_loading", comment: ""))
                                .foregroundColor(.secondary)
                        } else {
                            Text(NSLocalizedString("party.no_moves_found", comment: ""))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
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
                                        Text(NSLocalizedString("move.power_label", comment: "") + " \(power)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    if let accuracy = move.accuracy {
                                        Text(NSLocalizedString("move.accuracy_label", comment: "") + " \(accuracy)")
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
                }
            }
            .searchable(text: $searchText, prompt: NSLocalizedString("party.search_moves", comment: ""))
            .navigationTitle(String(format: NSLocalizedString("party.select_move_title", comment: ""), selectedMoveSlot + 1))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "")) {
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
                    Text(String(format: NSLocalizedString("party.evs_remaining", comment: ""), remainingEVs))
                        .font(.headline)
                        .foregroundColor(remainingEVs >= 0 ? .primary : .red)
                } header: {
                    Text(String(format: NSLocalizedString("party.evs_total", comment: ""), evs.total))
                }

                Section {
                    EVStatRow(label: NSLocalizedString("stat.hp", comment: ""), value: $evs.hp, remaining: remainingEVs)
                    EVStatRow(label: NSLocalizedString("stat.attack", comment: ""), value: $evs.attack, remaining: remainingEVs)
                    EVStatRow(label: NSLocalizedString("stat.defense", comment: ""), value: $evs.defense, remaining: remainingEVs)
                    EVStatRow(label: NSLocalizedString("stat.special_attack", comment: ""), value: $evs.specialAttack, remaining: remainingEVs)
                    EVStatRow(label: NSLocalizedString("stat.special_defense", comment: ""), value: $evs.specialDefense, remaining: remainingEVs)
                    EVStatRow(label: NSLocalizedString("stat.speed", comment: ""), value: $evs.speed, remaining: remainingEVs)
                }

                Section {
                    Button(NSLocalizedString("party.reset_all", comment: "")) {
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
            .navigationTitle(NSLocalizedString("party.edit_evs_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.done", comment: "")) {
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

// MARK: - IV Editor Sheet

struct IVEditorSheet: View {
    @Binding var ivs: StatValues
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(String(format: NSLocalizedString("party.ivs_total", comment: ""), ivs.total))
                        .font(.headline)
                } header: {
                    Text(NSLocalizedString("party.ivs_settings", comment: ""))
                }

                Section {
                    IVStatRow(label: NSLocalizedString("stat.hp", comment: ""), value: $ivs.hp)
                    IVStatRow(label: NSLocalizedString("stat.attack", comment: ""), value: $ivs.attack)
                    IVStatRow(label: NSLocalizedString("stat.defense", comment: ""), value: $ivs.defense)
                    IVStatRow(label: NSLocalizedString("stat.special_attack", comment: ""), value: $ivs.specialAttack)
                    IVStatRow(label: NSLocalizedString("stat.special_defense", comment: ""), value: $ivs.specialDefense)
                    IVStatRow(label: NSLocalizedString("stat.speed", comment: ""), value: $ivs.speed)
                }

                Section {
                    Button(NSLocalizedString("party.set_all_max_31", comment: "")) {
                        ivs = StatValues.maxIVs
                    }

                    Button(NSLocalizedString("party.set_all_0", comment: "")) {
                        ivs = StatValues.zero
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle(NSLocalizedString("party.edit_ivs_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.done", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - IV Stat Row

struct IVStatRow: View {
    let label: String
    @Binding var value: Int

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
                    if value > 0 {
                        value -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                }
                .disabled(value == 0)

                Slider(value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ), in: 0...31, step: 1)

                Button {
                    if value < 31 {
                        value += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .disabled(value >= 31)
            }
        }
    }
}
