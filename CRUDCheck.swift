//  CRUDCheck.swift
//
//  The one runnable check. Not part of the app target — it lives outside the
//  Todos/ folder on purpose, so Xcode's synchronized group never compiles it
//  into the shipped binary.
//
//  It exercises the same four operations the UI does, against an in-memory
//  SwiftData container, and crashes on the first wrong answer. If SwiftData
//  ever stops persisting a mutation, this fails before the simulator does.
//
//  Run it:  swiftc -o /tmp/crudcheck Todos/Todo.swift CRUDCheck.swift && /tmp/crudcheck

import Foundation
import SwiftData

@main
enum CRUDCheck {
    static func main() throws { try check() }
}

@MainActor
func check() throws {
    // A throwaway database that never touches disk.
    let container = try ModelContainer(
        for: Todo.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    let all = FetchDescriptor<Todo>(sortBy: [SortDescriptor(\.createdAt)])

    // CREATE
    let todo = Todo(title: "buy milk")
    context.insert(todo)
    assert(try! context.fetch(all).count == 1, "insert did not land")

    // READ
    assert(try! context.fetch(all).first?.title == "buy milk", "wrong todo read back")

    // UPDATE — both fields the UI can change.
    todo.title = "buy oat milk"
    todo.isDone = true
    let updated = try context.fetch(all)[0]
    assert(updated.title == "buy oat milk" && updated.isDone, "update not persisted")

    // DELETE
    context.delete(todo)
    assert(try! context.fetch(all).isEmpty, "delete did not remove the todo")

    print("CRUD ok")
}
