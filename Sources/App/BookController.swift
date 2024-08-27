//
//  File.swift
//  Bookshelf
//
//  Created by Glenn Hevey on 25/8/2024.
//

import Foundation
import Hummingbird

struct BookController<Repository: BookRepository> {
    let repository: Repository
    
    func addRoutes(to group: RouterGroup<some RequestContext>) {
        group
            .get(":id", use: get)
            .get(use: list)
            .post(use: create)
            .patch(":id", use: update)
            .delete(":id", use: delete)
            .delete(use: deleteAll)
    }
    
    @Sendable func get(request: Request, context: some RequestContext) async throws -> Book? {
        let id = try context.parameters.require("id", as: UUID.self)
        return try await self.repository.get(id: id)
    }
    
    @Sendable func list(request: Request, context: some RequestContext) async throws -> [Book] {
        return try await self.repository.list()
    }
    
    struct CreateRequest: Decodable {
        let title: String
        let path: String
    }
    
    @Sendable func create(request: Request, context: some RequestContext) async throws -> EditedResponse<Book> {
        let request = try await request.decode(as: CreateRequest.self, context: context)
        let book = try await self.repository.create(title: request.title, path: request.path)
        
        return EditedResponse(status: .created, response: book)
    }
    
    struct UpdateRequest: Decodable {
        var title: String?
        var path: String?
    }
    
    @Sendable func update(request: Request, context: some RequestContext) async throws -> Book? {
        let id = try context.parameters.require("id", as: UUID.self)
        let request = try await request.decode(as: UpdateRequest.self, context: context)
        guard let book = try await self.repository.update(
            id: id,
            title: request.title,
            path: request.path
        ) else {
            throw HTTPError(.badRequest)
        }
        
        return book
    }
    
    @Sendable func delete(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        let id = try context.parameters.require("id", as: UUID.self)
        if try await self.repository.delete(id: id) {
            return .ok
        } else {
            return .badRequest
        }
    }
    
    @Sendable func deleteAll(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        try await self.repository.deleteAll()
        return .ok
    }
}
