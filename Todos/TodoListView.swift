//  TodoListView.swift
//
//  The entire user interface, and all four CRUD operations, in one file.
//
//  Create  — the + button inserts a blank Todo and focuses it.
//  Read    — @Query pulls every Todo out of the database, newest last.
//  Update  — each row's TextField is bound straight to `todo.title`, so typing
//            *is* the update. Tapping the circle flips `isDone`.
//  Delete  — swipe a row, or leave a row blank and tap away.
//
//  There is no view model. SwiftData's @Query and @Bindable already give the
//  view an observable, writable connection to storage; a layer in between
//  would only forward messages.
//
//  Styling lives in the `Ink` enum at the top: a near-black canvas, warm
//  paper-white text, one ember accent. Headings use New York (SwiftUI's serif)
//  to keep the app from looking like the default template.

import SwiftUI
import SwiftData

/// The whole palette. Four colors is enough; more would just be noise.
private enum Ink {
    static let canvas = Color(red: 0.05, green: 0.05, blue: 0.06)   // near-black background
    static let paper  = Color(red: 0.93, green: 0.91, blue: 0.87)   // warm off-white text
    static let faded  = Color(red: 0.42, green: 0.41, blue: 0.40)   // completed / secondary
    static let ember  = Color(red: 0.94, green: 0.65, blue: 0.29)   // the single accent
}

struct TodoListView: View {
    /// Reads the database and re-renders whenever it changes. The sort keeps
    /// new todos at the bottom instead of jumping around.
    @Query(sort: \Todo.createdAt) private var todos: [Todo]

    /// The live database connection injected by `.modelContainer` in TodosApp.
    @Environment(\.modelContext) private var context

    /// Which row's text field currently has the keyboard. Identified by the
    /// todo's persistent ID so a freshly created row can grab focus.
    @FocusState private var focused: PersistentIdentifier?

    var body: some View {
        NavigationStack {
            List {
                ForEach(todos) { todo in
                    TodoRow(todo: todo, focused: $focused)
                }
                .onDelete(perform: delete)
                .listRowBackground(Ink.canvas)
                .listRowSeparatorTint(Ink.faded.opacity(0.25))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)          // let our canvas show through
            .background(Ink.canvas)
            .overlay { if todos.isEmpty { emptyState } }
            .navigationTitle("Todos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New todo", systemImage: "plus", action: create)
                        .tint(Ink.ember)
                }
                ToolbarItem(placement: .status) { remainingCount }
            }
            .toolbarBackground(Ink.canvas, for: .navigationBar, .bottomBar)
        }
        .tint(Ink.ember)
    }

    /// Shown instead of an empty list — a blank screen reads as a bug.
    private var emptyState: some View {
        Text("Nothing to do.")
            .font(.system(.title3, design: .serif))
            .foregroundStyle(Ink.faded)
    }

    private var remainingCount: some View {
        Text("\(todos.count(where: { !$0.isDone })) left")
            .font(.footnote)
            .foregroundStyle(Ink.faded)
    }

    /// CREATE — insert a blank todo and hand it the keyboard. If the user taps
    /// away without typing, `TodoRow` cleans it up.
    private func create() {
        let todo = Todo(title: "")
        context.insert(todo)
        focused = todo.persistentModelID
    }

    /// DELETE — `offsets` are indices into `todos`, which is already sorted the
    /// same way the rows are drawn, so they line up.
    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(todos[index]) }
    }
}

/// One line of the list. Split out so `@Bindable` can wrap a single todo and
/// give the TextField a two-way binding into the database.
private struct TodoRow: View {
    @Bindable var todo: Todo
    @FocusState.Binding var focused: PersistentIdentifier?
    @Environment(\.modelContext) private var context

    var body: some View {
        HStack(spacing: 14) {
            // UPDATE (done) — a tappable circle rather than a Toggle, so the
            // checked state can carry the accent color.
            Button {
                todo.isDone.toggle()
            } label: {
                Image(systemName: todo.isDone ? "circle.inset.filled" : "circle")
                    .font(.title3)
                    .foregroundStyle(todo.isDone ? Ink.ember : Ink.faded)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(todo.isDone ? "Mark as not done" : "Mark as done")

            // UPDATE (title) — typing here writes directly to the model.
            TextField("New todo", text: $todo.title)
                .font(.system(.body, design: .serif))
                .foregroundStyle(todo.isDone ? Ink.faded : Ink.paper)
                .strikethrough(todo.isDone, color: Ink.faded)
                .focused($focused, equals: todo.persistentModelID)
                .submitLabel(.done)
        }
        .padding(.vertical, 6)
        .animation(.snappy, value: todo.isDone)
        .onChange(of: focused) { _, now in
            // A row left blank was never really created — drop it rather than
            // leaving an untappable empty line in the list.
            if now != todo.persistentModelID, todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
                context.delete(todo)
            }
        }
    }
}

#Preview {
    TodoListView()
        .modelContainer(for: Todo.self, inMemory: true)
}
