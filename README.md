# Todos

A deliberately small iOS todo app. SwiftUI + SwiftData, Swift 6, iOS 26. No
dependencies, no view models, no architecture diagram — except the one below,
which is the whole thing.

## Files

| File | What it is |
|---|---|
| `Todos/Todo.swift` | The `@Model` class. The entire persistence layer. |
| `Todos/TodosApp.swift` | App entry point: one window, one model container, dark mode. |
| `Todos/TodoListView.swift` | The whole UI and all four CRUD operations. |
| `CRUDCheck.swift` | Standalone assert-based check. Not in the app target. |

Every file opens with what it is, how data flows through it, and who calls it —
and closes with what happens next.

## Data flow

```mermaid
flowchart TD
    OS([iOS launches the app]) --> App

    subgraph setup [Startup]
        App["<b>TodosApp</b><br/>@main"]
        DB[("<b>SwiftData</b><br/>SQLite on disk")]
        App -- ".modelContainer(for: Todo.self)<br/>opens the store" --> DB
        App -- "injects ModelContext<br/>into the Environment" --> List
    end

    subgraph screen [The only screen]
        List["<b>TodoListView</b><br/>@Query todos"]
        Row["<b>TodoRow</b><br/>@Bindable todo"]
        List -- "ForEach: one row per todo" --> Row
    end

    Model["<b>Todo</b><br/>title · isDone · createdAt"]

    DB -- "① READ<br/>@Query streams rows in<br/>and re-renders on change" --> List
    List -- "② CREATE — context.insert()<br/>④ DELETE — context.delete()" --> DB
    Row -- "③ UPDATE<br/>TextField ↔ todo.title<br/>circle ↔ todo.isDone" --> Model
    Model -- "SwiftData autosaves<br/>and notifies @Query" --> DB

    Check["<b>CRUDCheck</b><br/>separate executable"] -. "same four calls,<br/>in-memory store, no UI" .-> Model

    style DB fill:#1c1c22,stroke:#f0a64b,color:#eee
    style Model fill:#1c1c22,stroke:#f0a64b,color:#eee
    style Check fill:#1c1c22,stroke:#6b6b68,color:#999,stroke-dasharray: 4 4
```

Read it as one loop: **the database draws the list, the list mutates the model,
the model writes back to the database, and that write redraws the list.** There
is no layer in between — `@Query` and `@Bindable` *are* the wiring.

## CRUD

| | Where | What actually happens |
|---|---|---|
| **Create** | `TodoListView.create()` | `+` inserts a blank `Todo`, then hands it the keyboard. |
| **Read** | `@Query(sort: \Todo.createdAt)` | Streams the store into the list; re-renders itself on any change. |
| **Update** | `TodoRow` | `TextField` is bound straight to `todo.title`; the circle toggles `isDone`. |
| **Delete** | `TodoListView.delete(at:)` | Swipe a row — or leave one blank and tap away. |

## Design

Near-black canvas, warm paper-white text, one ember accent, New York serif for
body text. Four colors total, defined in the `Ink` enum at the top of
`TodoListView.swift`.

## Run

```sh
open Todos.xcodeproj      # then ⌘R
```

Or from the terminal:

```sh
xcodebuild -project Todos.xcodeproj -scheme Todos \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Check

```sh
swiftc -o /tmp/crudcheck -parse-as-library Todos/Todo.swift CRUDCheck.swift && /tmp/crudcheck
# CRUD ok
```
