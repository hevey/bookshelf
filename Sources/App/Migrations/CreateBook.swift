//
//  CreateBook.swift
//  Bookshelf
//
//  Created by Glenn Hevey on 31/8/2024.
//

import Fluent

struct CreateBook: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("books")
            .id()
            .field("title", .string, .required)
            .field("path", .string, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("books").delete()
    }
}
