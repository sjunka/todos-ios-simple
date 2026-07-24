//  Todos/Models/Todo.swift
//  ---------------------------------------------------------------------------
//  EL MODELO. Una sola clase: toda la capa de persistencia del app.
//
//  @Model reescribe la clase en compilación para que cada propiedad sea:
//    1. una columna en un archivo SQLite en disco,
//    2. observable por SwiftUI (cambiarla redibuja la vista),
//    3. guardada sola en el siguiente autosave.
//  O sea: escribir en memoria ES escribir en disco. No hay paso intermedio.
//
//  QUIÉN LO USA
//    App/TodosApp.swift        lo registra en el contenedor
//    Views/TodoListView.swift  lo consulta con @Query y lo muta
//    CRUDCheck.swift           lo prueba contra un contenedor en memoria
//
//  Este archivo casi nunca cambia. Agregar campos aquí es la única forma
//  correcta de crecer el modelo.
//  ---------------------------------------------------------------------------

import Foundation                                  // Date, el único tipo de Foundation que se usa aquí
import SwiftData                                   // trae @Model, el macro que convierte la clase en tabla

@Model                                             // genera el almacenamiento en disco y la observación
final class Todo {                                 // final: nadie hereda de esto, el compilador optimiza mejor

    /// Lo que el usuario escribió. Mutar esto desde una vista ES el "update":
    /// SwiftData persiste el cambio solo, sin llamar save().
    var title: String                              // var, no let: la edición en línea lo reescribe

    /// Tachado o no. Lo único más que puede pasarle a un todo.
    var isDone: Bool                               // Bool y no un enum de estados: solo hay dos

    /// Llave de orden, para que la lista tenga un orden estable en vez del
    /// orden natural indefinido de SwiftData.
    var createdAt: Date                            // se fija una vez y nunca se vuelve a tocar

    /// Único inicializador. Solo pide el título porque los otros dos campos
    /// tienen un valor correcto obvio al nacer.
    init(title: String) {                          // llamado desde TodoListView.create()
        self.title = title                         // puede venir vacío: la fila recién creada arranca en blanco
        self.isDone = false                        // un todo nuevo nunca nace hecho
        self.createdAt = .now                      // sella el momento para poder ordenar después
    }
}

//  ---------------------------------------------------------------------------
//  QUÉ PASA DESPUÉS
//  Nada, desde este archivo. Modelo puro: no navega, no dibuja, no llama a
//  nadie. Solo lo llaman a él.
//
//  Al insertar una instancia en el ModelContext (TodoListView.create), SwiftData
//  la escribe y notifica a todos los @Query activos, que redibujan la lista.
//  Al borrarla (swipe, o fila vacía), pasa lo mismo al revés.
//  ---------------------------------------------------------------------------
