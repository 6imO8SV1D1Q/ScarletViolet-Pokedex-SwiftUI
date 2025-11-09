//
//  ScarletViolet_Pokedex_SwiftUIApp.swift
//  ScarletViolet-Pokedex-SwiftUI
//
//  Created by 阿部友祐 on 2025/11/09.
//

import SwiftUI
import SwiftData

@main
struct ScarletViolet_Pokedex_SwiftUIApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
