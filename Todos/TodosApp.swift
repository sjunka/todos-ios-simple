//  TodosApp.swift
//
//  The entry point. Three jobs, nothing more:
//
//  1. Declare the single window (`WindowGroup`) that holds the UI.
//  2. Hand SwiftData the list of model types it should manage. That one
//     `.modelContainer` line creates the database file, migrates it, and
//     injects a live `ModelContext` into the SwiftUI environment so any view
//     below can read and write todos.
//  3. Force dark mode. The app is designed for a near-black canvas; letting it
//     flip to light would wash out the palette in Theme.swift.

import SwiftUI
import SwiftData

@main
struct TodosApp: App {
    var body: some Scene {
        WindowGroup {
            TodoListView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: Todo.self)
    }
}
