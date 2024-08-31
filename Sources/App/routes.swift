import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Bookshelf!"])
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    try app.register(collection: BookController())
}
