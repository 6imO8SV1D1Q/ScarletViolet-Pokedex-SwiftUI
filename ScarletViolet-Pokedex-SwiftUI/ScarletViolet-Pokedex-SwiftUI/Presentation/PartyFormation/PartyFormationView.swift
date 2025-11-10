//
//  PartyFormationView.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Party Formation screen - create/edit party
//
//  Created by Claude on 2025-11-09.
//

import SwiftUI
import Kingfisher

struct PartyFormationView: View {
    @StateObject var viewModel: PartyFormationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingPokemonSelector = false
    @State private var selectedSlotIndex: Int?
    @State private var showingMemberEditor = false
    @State private var editingMemberIndex: Int?

    var body: some View {
        Form {
            Section(NSLocalizedString("party.party_name", comment: "")) {
                TextField(NSLocalizedString("party.party_name", comment: ""), text: $viewModel.party.name)
            }

            Section(String(format: NSLocalizedString("party.members", comment: ""), viewModel.party.members.count)) {
                ForEach(0..<6, id: \.self) { index in
                    if index < viewModel.party.members.count {
                        Button {
                            editingMemberIndex = index
                            showingMemberEditor = true
                        } label: {
                            PartyMemberRow(
                                member: viewModel.party.members[index],
                                pokemon: viewModel.memberPokemons[index]
                            )
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.removePokemon(at: index)
                            } label: {
                                Label(NSLocalizedString("party.remove", comment: ""), systemImage: "trash")
                            }
                        }
                    } else {
                        Button {
                            selectedSlotIndex = index
                            showingPokemonSelector = true
                        } label: {
                            EmptyMemberSlot(position: index + 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let analysis = viewModel.typeAnalysis {
                Section(NSLocalizedString("party.analysis", comment: "")) {
                    HStack {
                        Text(NSLocalizedString("party.coverage_score", comment: ""))
                        Spacer()
                        Text("\(Int(analysis.coverageScore * 100))%")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("party.formation_title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(NSLocalizedString("common.cancel", comment: "")) {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(NSLocalizedString("common.save", comment: "")) {
                    Task {
                        try? await viewModel.saveParty()
                        dismiss()
                    }
                }
                .disabled(viewModel.party.name.isEmpty)
            }
        }
        .sheet(isPresented: $showingPokemonSelector) {
            PartyPokemonSelectorSheet { pokemon in
                if let index = selectedSlotIndex {
                    viewModel.addPokemon(pokemon, at: index)
                }
            }
        }
        .sheet(isPresented: $showingMemberEditor) {
            if let index = editingMemberIndex,
               index < viewModel.party.members.count {
                NavigationStack {
                    PartyMemberEditorView(
                        viewModel: DIContainer.shared.makePartyMemberEditorViewModel(
                            member: viewModel.party.members[index]
                        ),
                        member: $viewModel.party.members[index]
                    )
                }
            }
        }
        .task {
            await viewModel.analyzeTypeMatchups()
            await viewModel.loadMemberPokemons()
        }
        .onChange(of: viewModel.party.members) { _, _ in
            Task {
                await viewModel.loadMemberPokemons()
            }
        }
    }
}

struct PartyMemberRow: View {
    let member: PartyMember
    let pokemon: Pokemon?

    var body: some View {
        HStack(spacing: 12) {
            // Pokemon sprite
            if let pokemon = pokemon, let imageURL = pokemon.displayImageURL {
                KFImage(URL(string: imageURL))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text("#\(member.pokemonId)")
                            .font(.caption2)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(pokemon?.displayName ?? "Pokemon #\(member.pokemonId)")
                        .font(.body)
                    if let nickname = member.nickname {
                        Text("(\(nickname))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    Label("Lv.\(member.level)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Tera type badge
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.caption2)
                        Text(member.teraType.capitalized)
                            .font(.caption2)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EmptyMemberSlot: View {
    let position: Int

    var body: some View {
        HStack {
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(.secondary.opacity(0.3))
                .frame(width: 50, height: 50)

            Text(String(format: NSLocalizedString("party.empty_slot", comment: ""), position))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
