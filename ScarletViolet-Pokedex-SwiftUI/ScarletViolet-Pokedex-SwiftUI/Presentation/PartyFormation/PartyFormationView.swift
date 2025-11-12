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
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var showingPokemonSelector = false
    @State private var selectedSlotIndex: Int?
    @State private var showingMemberEditor = false
    @State private var editingMemberIndex: Int?

    var body: some View {
        Form {
            Section(NSLocalizedString("party.party_name", comment: "")) {
                TextField(NSLocalizedString("party.party_name", comment: ""), text: $viewModel.party.name)
            }

            Section(String(format: NSLocalizedString("party.members", comment: ""), viewModel.sortedMembers.count)) {
                ForEach(0..<6, id: \.self) { index in
                    if index < viewModel.sortedMembers.count {
                        Button {
                            editingMemberIndex = index
                            showingMemberEditor = true
                        } label: {
                            PartyMemberRow(
                                member: viewModel.sortedMembers[index],
                                pokemon: index < viewModel.memberPokemons.count ? viewModel.memberPokemons[index] : nil
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
               index < viewModel.sortedMembers.count {
                // Find the actual index in party.members array
                let sortedMember = viewModel.sortedMembers[index]
                if let actualIndex = viewModel.party.members.firstIndex(where: { $0.id == sortedMember.id }) {
                    NavigationStack {
                        PartyMemberEditorView(
                            viewModel: DIContainer.shared.makePartyMemberEditorViewModel(
                                member: viewModel.party.members[actualIndex]
                            ),
                            member: $viewModel.party.members[actualIndex]
                        )
                    }
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
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var heldItem: ItemEntity?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignConstants.Spacing.small) {
            HStack(alignment: .top, spacing: DesignConstants.Spacing.small) {
                pokemonImage

                VStack(alignment: .leading, spacing: DesignConstants.Spacing.xxSmall) {
                    pokemonInfo
                }

                Spacer()
            }
        }
        .padding(.vertical, DesignConstants.Spacing.xxSmall)
        .task {
            await loadHeldItem()
        }
        .onChange(of: member.item) { _, _ in
            Task {
                await loadHeldItem()
            }
        }
    }

    private func loadHeldItem() async {
        guard let itemName = member.item, !itemName.isEmpty else {
            heldItem = nil
            return
        }

        let itemProvider = DIContainer.shared.itemProvider
        heldItem = try? await itemProvider.fetchItem(name: itemName)
    }

    private var pokemonImage: some View {
        Group {
            if let pokemon = pokemon, let imageURL = pokemon.displayImageURL {
                KFImage(URL(string: imageURL))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: DesignConstants.ImageSize.medium, height: DesignConstants.ImageSize.medium)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
                    .shadow(color: Color(.systemGray).opacity(DesignConstants.Shadow.opacity), radius: DesignConstants.Shadow.medium, x: 0, y: 2)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: DesignConstants.ImageSize.medium, height: DesignConstants.ImageSize.medium)
                    .overlay {
                        Text("#\(member.pokemonId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
            }
        }
    }

    private var pokemonInfo: some View {
        VStack(alignment: .leading, spacing: DesignConstants.Spacing.xxSmall) {
            pokemonHeader
            typesBadges

            HStack(spacing: 8) {
                Text("Lv.\(member.level)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let pokemon = pokemon, let ability = pokemon.abilities.first {
                    Text(localizationManager.displayName(for: ability))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let pokemon = pokemon {
                baseStatsView(pokemon)
            }

            // Tera type and nickname
            HStack(spacing: 8) {
                Text("テラスタイプ：\(teraTypeDisplayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let nickname = member.nickname {
                    Text("(\(nickname))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Held item
            if let item = heldItem {
                Text("持ち物：\(item.nameJa)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var teraTypeDisplayName: String {
        let teraType = PokemonType(slot: 1, name: member.teraType, nameJa: nil)
        return localizationManager.displayName(for: teraType)
    }

    private var pokemonHeader: some View {
        HStack(spacing: DesignConstants.Spacing.xSmall) {
            Text(String(format: "#%04d", member.pokemonId))
                .font(.caption)
                .foregroundColor(.secondary)

            if let pokemon = pokemon {
                Text(localizationManager.displayName(for: pokemon))
                    .font(.headline)
            } else {
                Text("Pokemon #\(member.pokemonId)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var typesBadges: some View {
        HStack(spacing: DesignConstants.Spacing.xxSmall) {
            if let pokemon = pokemon {
                ForEach(pokemon.types.sorted(by: { $0.slot < $1.slot })) { type in
                    Text(localizationManager.displayName(for: type))
                        .typeBadgeStyle(type)
                }
            }
        }
    }

    private func baseStatsView(_ pokemon: Pokemon) -> some View {
        let hp = pokemon.stats.first { $0.name == "hp" }?.baseStat ?? 0
        let attack = pokemon.stats.first { $0.name == "attack" }?.baseStat ?? 0
        let defense = pokemon.stats.first { $0.name == "defense" }?.baseStat ?? 0
        let specialAttack = pokemon.stats.first { $0.name == "special-attack" }?.baseStat ?? 0
        let specialDefense = pokemon.stats.first { $0.name == "special-defense" }?.baseStat ?? 0
        let speed = pokemon.stats.first { $0.name == "speed" }?.baseStat ?? 0
        let total = pokemon.totalBaseStat

        return HStack(spacing: 0) {
            Text("\(hp)")
            Text("-")
            Text("\(attack)")
            Text("-")
            Text("\(defense)")
            Text("-")
            Text("\(specialAttack)")
            Text("-")
            Text("\(specialDefense)")
            Text("-")
            Text("\(speed)")
            Text(" (")
            Text("\(total)")
            Text(")")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct EmptyMemberSlot: View {
    let position: Int

    var body: some View {
        HStack(spacing: DesignConstants.Spacing.small) {
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(.secondary.opacity(0.3))
                .frame(width: DesignConstants.ImageSize.medium, height: DesignConstants.ImageSize.medium)

            Text(String(format: NSLocalizedString("party.empty_slot", comment: ""), position))
                .foregroundColor(.secondary)
                .font(.headline)

            Spacer()
        }
        .padding(.vertical, DesignConstants.Spacing.xxSmall)
    }
}
