# Todos

App de tareas para iOS, deliberadamente pequeño. SwiftUI + SwiftData, Swift 6,
iOS 26. Sin dependencias, sin view models.

## Arquitectura

Agrupado por tipo — el layout estándar para un app chico (menos de ~10
pantallas). Pasado ese punto, reagrupar por feature, para que un cambio toque
una sola carpeta.

```
Todos/
├── App/        TodosApp.swift        punto de entrada, abre la base de datos
├── Models/     Todo.swift            clase @Model, la capa de persistencia
└── Views/      TodoListView.swift    la pantalla + TodoRow
CRUDCheck.swift                       prueba suelta, fuera del target del app
```

`Services/` (clientes de API, Keychain, etc.) va al lado de `Models/` — aparece
cuando haya un primer servicio que meterle, no antes.

Xcode toma estas carpetas solo: el target usa un grupo sincronizado con el
sistema de archivos, así que agregar un archivo al disco lo agrega al build.
No hay que editar `project.pbxproj`.

Cada archivo abre diciendo qué es y cómo fluyen los datos por él, lleva un
comentario corto por línea, y cierra con qué pasa después. Comentarios y
documentación en español; los strings de la UI están en inglés.

## Flujo de datos

```mermaid
flowchart TD
    OS([iOS arranca el app]) --> App

    subgraph setup [App/]
        App["<b>TodosApp</b><br/>@main"]
        DB[("<b>SwiftData</b><br/>SQLite en disco")]
        App -- ".modelContainer(for: Todo.self)<br/>abre el almacén" --> DB
        App -- "inyecta el ModelContext<br/>en el Environment" --> List
    end

    subgraph views [Views/]
        List["<b>TodoListView</b><br/>@Query todos"]
        Row["<b>TodoRow</b><br/>@Bindable todo"]
        List -- "ForEach: una fila por todo" --> Row
    end

    subgraph models [Models/]
        Model["<b>Todo</b><br/>title · isDone · createdAt"]
    end

    DB -- "① READ<br/>@Query trae las filas<br/>y redibuja al cambiar" --> List
    List -- "② CREATE — context.insert()<br/>④ DELETE — context.delete()" --> DB
    Row -- "③ UPDATE<br/>TextField ↔ todo.title<br/>círculo ↔ todo.isDone" --> Model
    Model -- "SwiftData guarda solo<br/>y avisa al @Query" --> DB

    Check["<b>CRUDCheck</b><br/>ejecutable aparte"] -. "las mismas cuatro llamadas,<br/>base en memoria, sin UI" .-> Model

    style DB fill:#1c1c22,stroke:#f0a64b,color:#eee
    style Model fill:#1c1c22,stroke:#f0a64b,color:#eee
    style Check fill:#1c1c22,stroke:#6b6b68,color:#999,stroke-dasharray: 4 4
```

Léelo como un solo ciclo: **la base dibuja la lista, la lista muta el modelo, el
modelo escribe de vuelta en la base, y esa escritura redibuja la lista.** No hay
capa en medio — `@Query` y `@Bindable` *son* el cableado.

## CRUD

| | Dónde | Qué pasa en realidad |
|---|---|---|
| **Create** | `TodoListView.create()` | El `+` inserta un `Todo` en blanco y le entrega el teclado. |
| **Read** | `@Query(sort: \Todo.createdAt)` | Trae el almacén a la lista; se redibuja solo ante cualquier cambio. |
| **Update** | `TodoRow` | El `TextField` está enlazado directo a `todo.title`; el círculo alterna `isDone`. |
| **Delete** | `TodoListView.delete(at:)` | Swipe sobre la fila — o dejarla en blanco y tocar afuera. |

## Diseño

Fondo casi negro, texto blanco cálido, un solo acento ámbar, serif New York para
el cuerpo. Cuatro colores en total, en el enum `Ink` arriba de `TodoListView.swift`.

## Correr

```sh
open Todos.xcodeproj      # después ⌘R
```

O desde la terminal:

```sh
xcodebuild -project Todos.xcodeproj -scheme Todos \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Probar

```sh
swiftc -o /tmp/crudcheck -parse-as-library Todos/Models/Todo.swift CRUDCheck.swift && /tmp/crudcheck
# CRUD ok
```
