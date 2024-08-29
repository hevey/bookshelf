//
//  BookPostgresRepository.swift
//  Bookshelf
//
//  Created by Glenn Hevey on 28/8/2024.
//

import Foundation
import PostgresNIO

struct BookPostgresRepository: BookRepository {
    let client: PostgresClient
    let logger: Logger
    
    func createTable() async throws {
        _ = try await client.withConnection { connection in
            connection.query("""
                CREATE TABLE IF NOT EXISTS books (
                    "id" uuid PRIMARY KEY,
                    "title" text NOT NULL,
                    "path" text
                )
                """,
                logger: logger
            )
        }
    }
    
    func create(title: String, path: String) async throws -> Book {
        let id = UUID()
        try await self.client.query(
            "INSERT INTO books (id, title, path) VALUES (\(id), \(title), \(path));",
            logger: logger
        )
        return Book(id: id, title: title, path: path)
    }
    
    func get(id: UUID) async throws -> Book? { 
        let stream = try await client.query("""
            SELECT "id", "title", "path" FROM books WHERE "id" = \(id)
            """, logger: logger
        )
        for try await (id, title, path) in stream.decode((UUID, String, String).self, context: .default) {
            return Book(id: id, title: title, path: path)
        }
        return nil
    }
    
    func list() async throws -> [Book] { 
        let stream = try await client.query("""
            SELECT "id", "title", "path" FROM books
            """, logger: logger
        )
        var books: [Book] = []
        for try await (id, title, path) in stream.decode((UUID, String, String).self, context: .default) {
            books.append(Book(id: id, title: title, path: path))
        }
        
        return books
    }
    
    func update(id: UUID, title: String?, path: String?) async throws -> Book? { 
        let query: PostgresQuery
        if let title = title, let path = path {
            query = """
                UPDATE books SET "title" = \(title), "path" = \(path) WHERE "id" = \(id)
                """
        } else if let title = title {
            query = """
                UPDATE books SET "title" = \(title) WHERE "id" = \(id)
                """
        } else if let path = path {
            query = """
                UPDATE books SET "path" = \(path) WHERE "id" = \(id)
                """
        } else {
            return nil
        }
        _ = try await client.query(query, logger: logger)

        let stream = try await client.query("""
            SELECT "id", "title", "path" FROM books WHERE "id" = \(id)
            """, logger: logger
        )
        for try await (id, title, path) in stream.decode((UUID, String, String).self, context: .default) {
            return Book(id: id, title: title, path: path)
        }
        return nil
     }
    
    func delete(id: UUID) async throws -> Bool { 
        let selectStream = try await client.query("""
            SELECT "id" FROM books WHERE "id" = \(id)
            """, logger: logger
        )
        if try await selectStream.decode((UUID).self, context: .default).first(where: { _ in true} ) == nil {
            return false
        }

        _ = try await client.query("DELETE FROM books WHERE id = \(id);", logger: logger)
        return true
    }
    
    func deleteAll() async throws {
        try await client.query("DELETE FROM books;", logger: logger)
    }

}
