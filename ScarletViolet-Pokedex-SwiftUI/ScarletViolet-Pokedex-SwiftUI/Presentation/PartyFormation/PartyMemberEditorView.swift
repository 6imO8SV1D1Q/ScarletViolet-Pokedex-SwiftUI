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
                HStack {
                    Text("EVs")
                    Spacer()
                    Text("\(viewModel.member.evs.total)/510")
                        .foregroundColor(.secondary)
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
                    if slot < viewModel.member.selectedMoves.count {
                        HStack {
                            Text("Move \(slot + 1)")
                            Spacer()
                            Text(viewModel.member.selectedMoves[slot].moveName)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Move \(slot + 1)")
                            Spacer()
                            Text("Empty")
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
        .task {
            await viewModel.loadPokemonData()
        }
    }
}
