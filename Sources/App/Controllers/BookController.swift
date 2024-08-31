//
//  BookController.swift
//  Bookshelf
//
//  Created by Glenn Hevey on 31/8/2024.
//

import Fluent
import Vapor

struct BookController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let books = routes.grouped("books")
        
        books.get(use: self.index)
        books.post(use: self.create)
        books.group(":bookID") { book in
            book.get(use: self.getById)
            book.delete(use: self.delete)
        }
    }
    
    @Sendable
    func index(_ req: Request) async throws -> [BookDTO] {
        try await Book.query(on: req.db).all().map { $0.toDTO() }
    }
    
    @Sendable
    func create(req: Request) async throws -> BookDTO {
        let book = try req.content.decode(BookDTO.self).toModel()
        
        try await book.save(on: req.db)
        return book.toDTO()
    }
    
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let book = try await Book.find(req.parameters.get("bookID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await book.delete(on: req.db)
        return .noContent
    }
    
    @Sendable
    func getById(req: Request) async throws -> BookDTO {
        guard let book = try await Book.find(req.parameters.get("bookID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return book.toDTO()
    }
}
