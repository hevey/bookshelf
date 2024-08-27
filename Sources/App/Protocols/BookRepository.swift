//
//  File.swift
//  Bookshelf
//
//  Created by Glenn Hevey on 26/8/2024.
//

import Foundation

/// Interface for storing and editing todos
protocol BookRepository {
    /// Create book.
    func create(title: String, path: String) async throws -> Book
    /// Get book
    func get(id: UUID) async throws -> Book?
    /// List all books
    func list() async throws -> [Book]
    /// Update book. Returns updated todo if successful
    func update(id: UUID, title: String?, path: String?) async throws -> Book?
    /// Delete book. Returns true if successful
    func delete(id: UUID) async throws -> Bool
    /// Delete all books
    func deleteAll() async throws
}
