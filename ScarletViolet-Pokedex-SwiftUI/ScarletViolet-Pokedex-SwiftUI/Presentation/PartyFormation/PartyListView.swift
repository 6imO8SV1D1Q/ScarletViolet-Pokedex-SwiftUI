//
//  PartyListView.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Party List screen - displays all saved parties
//
//  Created by Claude on 2025-11-09.
//

import SwiftUI

struct PartyListView: View {
    @StateObject var viewModel: PartyListViewModel
    @State private var showingNewPartySheet = false

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading parties...")
            } else if viewModel.parties.isEmpty {
                EmptyPartyView {
                    showingNewPartySheet = true
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.parties) { party in
                            NavigationLink {
                                PartyFormationView(
                                    viewModel: DIContainer.shared.makePartyFormationViewModel(party: party)
                                )
                            } label: {
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
                .refreshable {
                    await viewModel.loadParties()
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
            // Reload parties when sheet is dismissed
            Task {
                await viewModel.loadParties()
            }
        } content: {
            NavigationStack {
                PartyFormationView(
                    viewModel: DIContainer.shared.makePartyFormationViewModel()
                )
            }
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
        } message: { party in
            Text("Are you sure you want to delete '\(party.name)'?")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .task {
            await viewModel.loadParties()
        }
        .onAppear {
            // Refresh when returning from navigation
            if !viewModel.parties.isEmpty || viewModel.isLoading {
                Task {
                    await viewModel.loadParties()
                }
            }
        }
    }
}

struct EmptyPartyView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Parties")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first party to get started")
                .font(.body)
                .foregroundColor(.secondary)

            Button(action: onCreate) {
                Label("Create Party", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
    }
}

struct PartyCardView: View {
    let party: Party

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(party.name)
                    .font(.headline)
                Spacer()
                Text(party.updatedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Member count
            HStack {
                Label("\(party.members.count)/6", systemImage: "person.3.fill")
                    .font(.caption)
                Spacer()
                if !party.members.isEmpty {
                    Text("Avg. Lv. \(Int(party.averageLevel))")
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
