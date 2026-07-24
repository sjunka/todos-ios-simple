//  TodosApp.swift
//  ---------------------------------------------------------------------------
//  QUÉ ES
//  El punto de entrada. El primer código que corre al abrir el app.
//
//  FLUJO DE DATOS
//  Aquí nace la base de datos y aquí se inyecta hacia abajo:
//
//    .modelContainer(for: Todo.self)
//        └─ crea/abre el archivo SQLite y lo migra si hace falta
//        └─ mete un ModelContext vivo en el Environment de SwiftUI
//               └─ TodoListView lo saca con @Environment(\.modelContext)
//               └─ y @Query lee del mismo contenedor
//
//  Ningún dato pasa por este archivo. Solo abre la conexión y la deja
//  disponible para todo lo que cuelgue debajo.
//
//  QUIÉN LO USA
//  Nadie. @main lo llama el sistema operativo.
//
//  QUÉ SE ESPERA
//  Que se quede de este tamaño. Si el app crece, crece TodoListView o nacen
//  vistas nuevas, no este archivo.
//  ---------------------------------------------------------------------------

import SwiftUI                                     // App, Scene, WindowGroup
import SwiftData                                   // el modificador .modelContainer

@main                                              // marca el arranque del proceso, solo puede haber uno
struct TodosApp: App {                             // struct y no class: SwiftUI la recrea, no la muta

    var body: some Scene {                         // una Scene es una ventana del sistema, no una vista
        WindowGroup {                              // en iOS es la única pantalla; en iPad/Mac permite varias
            TodoListView()                         // la raíz de la UI; todo lo demás cuelga de aquí
                .preferredColorScheme(.dark)       // fuerza oscuro: la paleta de Ink se lava en claro
        }
        .modelContainer(for: Todo.self)            // única línea de setup de base de datos del proyecto
    }
}

//  ---------------------------------------------------------------------------
//  QUÉ PASA DESPUÉS
//  El sistema muestra el WindowGroup y el control se va a TodoListView, que ya
//  encuentra la base de datos lista en el Environment.
//
//  No hay navegación aquí: este archivo no decide pantallas, solo abre una.
//  El NavigationStack (y cualquier pantalla futura de detalle) vive dentro de
//  TodoListView.
//  ---------------------------------------------------------------------------
