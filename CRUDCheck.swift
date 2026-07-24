//  CRUDCheck.swift
//  ---------------------------------------------------------------------------
//  QUÉ ES
//  La única prueba corrible del proyecto. No usa XCTest ni framework alguno:
//  es un ejecutable que imprime "CRUD ok" o revienta en el primer assert falso.
//
//  FLUJO DE DATOS
//  Recorre el mismo camino que la UI, pero sin UI:
//
//    ModelContainer en memoria   (lo que en el app es el archivo SQLite)
//         │
//         ├─ context.insert(todo)     ← lo que hace el botón +
//         ├─ context.fetch(all)       ← lo que hace @Query
//         ├─ todo.title = "..."       ← lo que hace el TextField enlazado
//         ├─ todo.isDone = true       ← lo que hace el botón del círculo
//         └─ context.delete(todo)     ← lo que hace el swipe
//
//  Cada paso se vuelve a leer de la base antes de afirmar nada, para probar que
//  el dato quedó guardado y no solo cambiado en memoria.
//
//  POR QUÉ VIVE FUERA DE Todos/
//  Xcode compila la carpeta Todos/ entera (grupo sincronizado con el sistema de
//  archivos). Dejar esta prueba afuera es lo que impide que entre al binario.
//
//  QUÉ SE ESPERA
//  Que si SwiftData deja de persistir alguna mutación, esto falle antes que el
//  simulador y sin tener que tocar la pantalla.
//
//  Correr:
//    swiftc -o /tmp/crudcheck -parse-as-library Todos/Todo.swift CRUDCheck.swift
//    /tmp/crudcheck
//  ---------------------------------------------------------------------------

import Foundation                                  // pareja del import de Todo.swift, que se compila junto
import SwiftData                                   // ModelContainer, ModelConfiguration, FetchDescriptor

@main                                              // punto de entrada del ejecutable de prueba, no del app
enum CRUDCheck {                                   // enum sin casos: solo cuelga main(), nadie lo instancia
    static func main() throws { try check() }      // throws: si el contenedor no abre, el error sale al shell
}

@MainActor                                         // mainContext de SwiftData está atado al hilo principal
func check() throws {
    // Una base de datos desechable que nunca toca el disco.
    let container = try ModelContainer(
        for: Todo.self,                            // el mismo modelo que registra TodosApp
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)  // se evapora al terminar: cero limpieza
    )
    let context = container.mainContext             // el equivalente al \.modelContext del Environment
    let all = FetchDescriptor<Todo>(sortBy: [SortDescriptor(\.createdAt)])  // mismo orden que el @Query de la lista

    // CREATE
    let todo = Todo(title: "buy milk")             // nace con título, a diferencia del app (que crea en blanco)
    context.insert(todo)                           // lo que hace el botón +
    assert(try! context.fetch(all).count == 1, "insert did not land")  // relee de la base: no confía en la variable

    // READ
    assert(try! context.fetch(all).first?.title == "buy milk", "wrong todo read back")  // el dato vuelve igual

    // UPDATE — los dos campos que la UI puede cambiar.
    todo.title = "buy oat milk"                    // lo que hace escribir en el TextField
    todo.isDone = true                             // lo que hace tocar el círculo
    let updated = try context.fetch(all)[0]        // relectura: prueba que se guardó, no solo que mutó
    assert(updated.title == "buy oat milk" && updated.isDone, "update not persisted")

    // DELETE
    context.delete(todo)                           // lo que hace el swipe
    assert(try! context.fetch(all).isEmpty, "delete did not remove the todo")  // no quedan restos

    print("CRUD ok")                               // única salida en caso feliz: silencio es sospechoso
}

//  ---------------------------------------------------------------------------
//  QUÉ PASA DESPUÉS
//  Nada. El proceso termina, la base en memoria se descarta y el código de
//  salida (0 o crash) es el resultado.
//
//  Nadie llama a este archivo desde el app: no se compila con él. Se corre a
//  mano, o desde CI, con la línea de swiftc del encabezado.
//
//  Si algún día se agregan campos a Todo, el bloque UPDATE es el que hay que
//  extender: es el que prueba que una mutación sobrevive a la relectura.
//  ---------------------------------------------------------------------------
