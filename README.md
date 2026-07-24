# Todos

A deliberately small iOS todo app. SwiftUI + SwiftData, Swift 6, iOS 26. No
dependencies, no view models, no architecture diagram.

## Files

| File | What it is |
|---|---|
| `Todos/Todo.swift` | The `@Model` class. The entire persistence layer. |
| `Todos/TodosApp.swift` | App entry point: one window, one model container, dark mode. |
| `Todos/TodoListView.swift` | The whole UI and all four CRUD operations. |
| `CRUDCheck.swift` | Standalone assert-based check. Not in the app target. |

Every file opens with a comment explaining why it exists.

## CRUD

- **Create** — `+` inserts a blank todo and focuses it.
- **Read** — `@Query` streams the database into the list.
- **Update** — each row's `TextField` is bound straight to `todo.title`; the circle toggles `isDone`.
- **Delete** — swipe a row, or leave one blank and tap away.

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
