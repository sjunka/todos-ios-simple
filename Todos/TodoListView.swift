//  TodoListView.swift
//  ---------------------------------------------------------------------------
//  QUÉ ES
//  Toda la interfaz y las cuatro operaciones CRUD, en un archivo.
//  Dos vistas: TodoListView (la pantalla) y TodoRow (una fila).
//
//  FLUJO DE DATOS — el ciclo completo, en un solo sentido y de vuelta
//
//    SwiftData (SQLite)
//         │  @Query lee y se suscribe
//         ▼
//    TodoListView ──ForEach──> TodoRow (una por todo)
//         │                        │
//         │                        │ @Bindable da enlace de ida y vuelta
//         │                        ▼
//         │                   TextField / botón círculo
//         │                        │  el usuario escribe o toca
//         │                        ▼
//         │                   todo.title / todo.isDone mutan
//         │                        │
//         └────────────────────────┘  SwiftData persiste y avisa a @Query,
//                                     que vuelve a dibujar. Ciclo cerrado.
//
//    Crear y borrar no pasan por el binding: van directo al modelContext
//    (context.insert / context.delete) y el @Query reacciona igual.
//
//  DÓNDE VIVE CADA OPERACIÓN
//    Create  — create(), botón +. Inserta un todo en blanco y le da el teclado.
//    Read    — @Query todos, ordenado por createdAt.
//    Update  — en TodoRow: el TextField enlazado y el botón del círculo.
//    Delete  — delete(at:) por swipe, y el .onChange que limpia filas vacías.
//
//  QUIÉN LO USA
//  TodosApp lo pone como raíz del WindowGroup. TodoRow es privada: solo la usa
//  el ForEach de este mismo archivo.
//
//  QUÉ SE ESPERA
//  No hay view model. @Query y @Bindable ya son la conexión observable y
//  escribible contra el almacenamiento; una capa en medio solo reenviaría.
//  ---------------------------------------------------------------------------

import SwiftUI                                     // View, List, NavigationStack
import SwiftData                                   // @Query, ModelContext, PersistentIdentifier

/// Toda la paleta. Cuatro colores alcanzan; más sería ruido.
private enum Ink {                                 // enum sin casos: espacio de nombres, imposible de instanciar
    static let canvas = Color(red: 0.05, green: 0.05, blue: 0.06)   // fondo casi negro, no negro puro (menos duro en OLED)
    static let paper  = Color(red: 0.93, green: 0.91, blue: 0.87)   // blanco cálido, evita el contraste frío del blanco puro
    static let faded  = Color(red: 0.42, green: 0.41, blue: 0.40)   // hecho y texto secundario: presente pero en segundo plano
    static let ember  = Color(red: 0.94, green: 0.65, blue: 0.29)   // el único acento; solo marca lo accionable
}

struct TodoListView: View {                        // la pantalla completa

    /// Lee la base de datos y se redibuja sola cuando cambia. El orden deja los
    /// nuevos abajo, en vez de saltar de posición.
    @Query(sort: \Todo.createdAt) private var todos: [Todo]   // la R del CRUD: no hay fetch manual en ningún lado

    /// La conexión viva a la base, inyectada por .modelContainer en TodosApp.
    @Environment(\.modelContext) private var context          // por aquí pasan create y delete

    /// Qué fila tiene el teclado ahora. Se identifica por el ID persistente del
    /// todo, para que una fila recién creada pueda pedir el foco.
    @FocusState private var focused: PersistentIdentifier?    // opcional: nil = teclado cerrado

    var body: some View {
        NavigationStack {                          // da el título grande y la barra superior; hoy no empuja pantallas
            List {                                 // List y no ScrollView: trae swipe-to-delete y reciclado gratis
                ForEach(todos) { todo in           // una fila por todo; Todo es Identifiable por ser @Model
                    TodoRow(todo: todo, focused: $focused)     // $focused pasa el foco por referencia, no copia
                }
                .onDelete(perform: delete)         // enchufa el swipe del sistema a delete(at:)
                .listRowBackground(Ink.canvas)     // sin esto cada fila pinta su gris por defecto encima del canvas
                .listRowSeparatorTint(Ink.faded.opacity(0.25)) // separador apenas visible: divide sin gritar
            }
            .listStyle(.plain)                     // quita las tarjetas agrupadas y los márgenes de iOS
            .scrollContentBackground(.hidden)      // apaga el fondo del scroll para que se vea el canvas
            .background(Ink.canvas)                // el fondo oscuro real de la pantalla
            .overlay { if todos.isEmpty { emptyState } }  // overlay y no else: no reordena la jerarquía de la lista
            .navigationTitle("Todos")              // título grande que se encoge al hacer scroll
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {     // esquina superior derecha, donde el pulgar espera crear
                    Button("New todo", systemImage: "plus", action: create)  // el texto es la etiqueta de accesibilidad
                        .tint(Ink.ember)           // único elemento con acento arriba: manda la vista
                }
                ToolbarItem(placement: .status) { remainingCount }  // barra inferior: información, no acción
            }
            .toolbarBackground(Ink.canvas, for: .navigationBar, .bottomBar) // evita el gris translúcido del sistema
        }
        .tint(Ink.ember)                           // color de acento heredado por todo lo interactivo de adentro
    }

    /// Se muestra en vez de una lista vacía: una pantalla en blanco se lee como
    /// un error.
    private var emptyState: some View {            // propiedad calculada y no función: no toma argumentos
        Text("Nothing to do.")
            .font(.system(.title3, design: .serif))  // serif (New York): saca al app del look de plantilla
            .foregroundStyle(Ink.faded)            // apagado: es un estado, no un mensaje importante
    }

    /// Contador de pendientes en la barra inferior.
    private var remainingCount: some View {
        Text("\(todos.count(where: { !$0.isDone })) left")  // count(where:) de Swift 6: sin filter intermedio
            .font(.footnote)                       // chico: dato de apoyo
            .foregroundStyle(Ink.faded)            // mismo gris que el estado vacío: misma jerarquía visual
    }

    /// CREATE — inserta un todo en blanco y le entrega el teclado. Si el usuario
    /// toca afuera sin escribir, TodoRow lo limpia.
    private func create() {
        let todo = Todo(title: "")                 // en blanco a propósito: el usuario escribe en la fila misma
        context.insert(todo)                       // aquí ya existe en la base; @Query dibuja la fila
        focused = todo.persistentModelID           // manda el teclado a esa fila: crear y escribir es un solo gesto
    }

    /// DELETE — los `offsets` son índices sobre `todos`, que ya viene ordenado
    /// igual que las filas dibujadas, así que coinciden.
    private func delete(at offsets: IndexSet) {    // IndexSet y no Int: el swipe puede traer varias filas
        for index in offsets { context.delete(todos[index]) }  // borrado real, no bandera: no hay papelera
    }
}

/// Una línea de la lista. Se separa para que @Bindable pueda envolver un solo
/// todo y darle al TextField un enlace de ida y vuelta contra la base de datos.
private struct TodoRow: View {                     // private: nadie fuera de este archivo la arma
    @Bindable var todo: Todo                       // @Bindable y no @State: el dueño del dato es SwiftData
    @FocusState.Binding var focused: PersistentIdentifier?  // foco compartido con el padre: solo una fila a la vez
    @Environment(\.modelContext) private var context        // la fila borra sola si queda vacía

    var body: some View {
        HStack(spacing: 14) {                      // 14pt: separa el círculo del texto sin abrir un hueco
            // UPDATE (hecho) — un círculo tocable en vez de un Toggle, para que
            // el estado marcado pueda llevar el color de acento.
            Button {
                todo.isDone.toggle()               // mutar el modelo es todo: SwiftData guarda y la vista redibuja
            } label: {
                Image(systemName: todo.isDone ? "circle.inset.filled" : "circle")  // relleno vs vacío: se lee de un vistazo
                    .font(.title3)                 // fija el tamaño del símbolo, no el del texto
                    .foregroundStyle(todo.isDone ? Ink.ember : Ink.faded)  // el acento solo aparece al completar
            }
            .buttonStyle(.plain)                   // sin esto, List convierte toda la fila en un botón
            .accessibilityLabel(todo.isDone ? "Mark as not done" : "Mark as done")  // el ícono solo no dice nada a VoiceOver

            // UPDATE (título) — escribir aquí escribe directo en el modelo.
            TextField("New todo", text: $todo.title)   // el $ es el enlace de ida y vuelta a la base de datos
                .font(.system(.body, design: .serif))  // mismo serif que el estado vacío: una sola voz tipográfica
                .foregroundStyle(todo.isDone ? Ink.faded : Ink.paper)  // lo hecho se apaga y cede el foco visual
                .strikethrough(todo.isDone, color: Ink.faded)          // tachado: el refuerzo que no depende del color
                .focused($focused, equals: todo.persistentModelID)     // se prende cuando el padre apunta a esta fila
                .submitLabel(.done)                // la tecla Return dice "Done" y solo cierra el teclado
        }
        .padding(.vertical, 6)                     // aire para que la fila supere el mínimo táctil de 44pt
        .animation(.snappy, value: todo.isDone)    // anima solo el completar; escribir no debe animarse
        .onChange(of: focused) { _, now in         // corre cuando el foco se va a otra fila o al vacío
            // Una fila que quedó en blanco nunca llegó a existir de verdad:
            // mejor borrarla que dejar una línea vacía intocable en la lista.
            if now != todo.persistentModelID, todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
                context.delete(todo)               // solo si el foco YA no es de esta fila: si no, borraría al escribir
            }
        }
    }
}

#Preview {                                         // vista rápida en Xcode, no entra al binario final
    TodoListView()
        .modelContainer(for: Todo.self, inMemory: true)  // base de mentira: el preview no ensucia los datos reales
}

//  ---------------------------------------------------------------------------
//  QUÉ PASA DESPUÉS
//  Nada: aquí termina el flujo. Es la última pantalla del app.
//
//  No navega. El NavigationStack está solo por el título grande y la barra; hoy
//  nunca empuja otra vista, porque editar pasa en la fila misma y no hay
//  pantalla de detalle que abrir.
//
//  Quién llama a quién:
//    TodosApp        -> TodoListView   (raíz del WindowGroup)
//    TodoListView    -> TodoRow        (una por cada todo del @Query)
//    TodoRow         -> Todo           (muta title / isDone directo)
//    ambas           -> modelContext   (insert / delete)
//
//  Si algún día hay pantalla de detalle, va aquí: envolver la fila en un
//  NavigationLink y el NavigationStack ya está puesto para empujarla.
//  ---------------------------------------------------------------------------
