//
//  File.swift
//  Bookshelf
//
//  Created by Glenn Hevey on 26/8/2024.
//

import Foundation

actor BookMemoryRepository: BookRepository {
    var books: [UUID: Book]
    
    init() {
        self.books = [:]
    }
    
    func create(title: String, path: String) async throws -> Book {
        let id = UUID()
        let book = Book(id: id, title: title, path: path)
        self.books[id] = book
        
        return book
    }
    
    func get(id: UUID) async throws -> Book? {
        return self.books[id]
    }
    
    func list() async throws -> [Book] {
        return self.books.values.map { $0 }
    }
    
    func update(id: UUID, title: String?, path: String?) async throws -> Book? {
        var book = self.books[id]
        if let title {
            book?.title = title
        }
        if let path {
            book?.path = path
        }
        
        self.books[id] = book
        
        return book
    }
    
    func delete(id: UUID) async throws -> Bool {
        if self.books[id] != nil {
            self.books[id] = nil
            return true
        }
        
        return false
    }
    
    func deleteAll() async throws {
        self.books = [:]
    }
    
    
}
