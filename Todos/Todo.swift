//  Todo.swift
//
//  The data. One SwiftData model class — that is the whole persistence layer.
//
//  @Model rewrites this class at compile time so every stored property is
//  backed by an on-disk SQLite column, observable by SwiftUI, and saved
//  automatically. No Codable, no file I/O, no repository, no view model.
//
//  Deleting this file's contents would delete the entire storage stack, which
//  is the point: there is nothing else to delete.

import Foundation
import SwiftData

@Model
final class Todo {
    /// What the user typed. Mutating it from a view is an "update" — SwiftData
    /// persists the change on the next autosave, no explicit save() needed.
    var title: String

    /// Checked off or not. The only other thing a todo can be.
    var isDone: Bool

    /// Sort key, so the list has a stable order instead of SwiftData's
    /// undefined natural order.
    var createdAt: Date

    init(title: String) {
        self.title = title
        self.isDone = false
        self.createdAt = .now
    }
}
