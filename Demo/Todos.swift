//
//  Todos.swift
//  
//
//  Created by Soroush Khanlou on 9/2/20.
//

import Foundation
import Meridian

// Specs
// https://www.todobackend.com/specs/index.html?https://meridian-demo.herokuapp.com/todos

struct IDParameter: URLParameterKey {
    public typealias DecodeType = String
}

extension ParameterKeys {
    var id: IDParameter {
        IDParameter()
    }
}

struct ListTodos: Route {

    static let route: RouteMatcher = .get(.root)

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        JSON(database.todos)
            .allowCORS()
    }

}

struct ClearTodos: Route {
    static let route: RouteMatcher = .delete(.root)

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        self.database.todos = []
        return JSON(database.todos)
            .allowCORS()
    }
}

struct CreateTodo: Route {
    static let route: RouteMatcher = .post(.root)

    @JSONBody var todo: Todo

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        self.database.todos.append(todo)
        return JSON(todo)
            .statusCode(.created)
            .allowCORS()
    }
}

struct ShowTodo: Route {
    static let route: RouteMatcher = .get("/\(\.id)")

    @URLParameter(\.id) var id

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        guard let todo = database.todos.first(where: { $0.id.uuidString == id }) else {
            throw NoRouteFound()
        }
        return JSON(todo).allowCORS()
    }

}

struct TodoPatch: Codable {
    var title: String?
    var completed: Bool?
    var order: Int?
}

struct EditTodo: Route {
    static let route: RouteMatcher = .patch("/\(\.id)")

    @URLParameter(\.id) var id

    @JSONBody var patch: TodoPatch

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        guard let index = database.todos.firstIndex(where: { $0.id.uuidString == id }) else {
            throw NoRouteFound()
        }
        if let newTitle = patch.title {
            database.todos[index].title = newTitle
        }
        if let newCompleted = patch.completed {
            database.todos[index].completed = newCompleted
        }
        if let newOrder = patch.order {
            database.todos[index].order = newOrder
        }
        return JSON(database.todos[index]).allowCORS()
    }
}

struct DeleteTodo: Route {
    static let route: RouteMatcher = .delete("/\(\.id)")

    @URLParameter(\.id) var id

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        database.todos.removeAll(where: { $0.id.uuidString == id })
        return EmptyResponse().allowCORS()
    }
}
