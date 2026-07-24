//  Todos/App/TodosApp.swift
//  ---------------------------------------------------------------------------
//  EL PUNTO DE ENTRADA. Lo primero que corre al abrir el app.
//  Abre la base de datos, la reparte hacia abajo, muestra la primera pantalla.
//
//  ORDEN DE ARRANQUE
//    iOS carga el proceso
//      └─ ve @main y construye TodosApp
//           └─ lee `body` y encuentra un WindowGroup
//                └─ .modelContainer abre el SQLite ANTES de dibujar
//                     └─ dibuja TodoListView, que ya encuentra la base lista
//
//  Ese orden importa: si el contenedor no se abriera primero, el @Query de
//  TodoListView no tendría de dónde leer.
//
//  Ningún dato pasa por aquí. Este archivo solo abre la conexión.
//  ---------------------------------------------------------------------------

import SwiftUI                                     // App, Scene, WindowGroup
import SwiftData                                   // el modificador .modelContainer

@main                                              // marca el arranque; solo puede haber uno en el target
struct TodosApp: App {                             // struct y no class: SwiftUI la recrea, no la muta

    // `body` no corre una vez: es una descripción que SwiftUI vuelve a leer
    // cada vez que algo cambia. Por eso aquí no va lógica.
    var body: some Scene {

        // Scene = ventana del sistema, no vista. En iOS solo se ve una; en
        // iPad/Mac el usuario abre varias, todas contra la MISMA base.
        WindowGroup {
            TodoListView()                         // raíz de la UI; todo lo demás cuelga de aquí
                .preferredColorScheme(.dark)       // fuerza oscuro: la paleta de Ink se lava en claro
        }

        // Única línea de setup de base de datos del proyecto. Por dentro:
        //   · abre (o crea) el archivo SQLite del app,
        //   · migra el esquema si Todo cambió desde la versión anterior,
        //   · mete un ModelContext vivo en el Environment de SwiftUI.
        // Ese Environment es lo que permite que TodoListView escriba sin que
        // nadie le pase la base por parámetro. Va sobre la Scene y no sobre la
        // vista, para que todas las ventanas compartan una sola conexión.
        .modelContainer(for: Todo.self)            // `for:` = modelos a gestionar; hoy solo uno
    }
}

//  ---------------------------------------------------------------------------
//  QUÉ PASA DESPUÉS
//  El control se va a TodoListView y no vuelve. Este archivo no navega.
//
//  Aquí crecería el app: registrar otro modelo en `for:`, o cambiar la vista
//  raíz por un TabView si aparece una segunda pantalla.
//  ---------------------------------------------------------------------------
