import Hummingbird
import HummingbirdTesting
import Logging
import XCTest

@testable import App

final class AppTests: XCTestCase {
    struct TestArguments: AppArguments {
        let hostname = "127.0.0.1"
        let port = 0
        let logLevel: Logger.Level? = .trace
        let inMemoryTesting = false
    }
    
    struct CreateRequest: Encodable {
            let title: String
            let path: String
        }
    
    func create(title: String, path: String, client: some TestClientProtocol) async throws -> Book {
        let request = CreateRequest(title: title, path: path)
        let buffer = try JSONEncoder().encodeAsByteBuffer(request, allocator: ByteBufferAllocator())
        return try await client.execute(uri: "/books", method: .post, body: buffer) { response in
            XCTAssertEqual(response.status, .created)
            return try JSONDecoder().decode(Book.self, from: response.body)
        }
    }
    
    func get(id: UUID, client: some TestClientProtocol) async throws -> Book? {
        try await client.execute(uri: "/books/\(id)", method: .get) { response in
            XCTAssert(response.status == .ok || response.body.readableBytes == 0)
            if response.body.readableBytes > 0 {
                return try JSONDecoder().decode(Book.self, from: response.body)
            } else {
                return nil
            }
        }
    }

    func list(client: some TestClientProtocol) async throws -> [Book] {
        try await client.execute(uri: "/books", method: .get) { response in
            XCTAssertEqual(response.status, .ok)
            return try JSONDecoder().decode([Book].self, from: response.body)
        }
    }

    struct UpdateRequest: Encodable {
        let title: String?
        let path: String?
    }
    
    func patch(id: UUID, title: String? = nil, path: String? = nil, client: some TestClientProtocol) async throws -> Book? {
        let request = UpdateRequest(title: title, path: path)
        let buffer = try JSONEncoder().encodeAsByteBuffer(request, allocator: ByteBufferAllocator())
        
        return try await client.execute(uri: "/books/\(id)", method: .patch, body: buffer) { response in
            XCTAssertEqual(response.status, .ok)
            if response.body.readableBytes > 0 {
                return try JSONDecoder().decode(Book.self, from: response.body)
            } else {
                return nil
            }
        }
    }

    func delete(id: UUID, client: some TestClientProtocol) async throws -> HTTPResponse.Status {
        try await client.execute(uri: "/books/\(id)", method: .delete) { response in
            response.status
        }
    }

    func deleteAll(client: some TestClientProtocol) async throws -> HTTPResponse.Status {
        try await client.execute(uri: "/books", method: .delete) { response in
            response.status
        }
    }
    
    func testApp() async throws {
        let args = TestArguments()
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(uri: "/health", method: .get) { response in
                XCTAssertEqual(response.status, .ok)
            }
        }
    }
    
    func testBookCreate() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            
            let book = try await self.create(title: "Book 1", path: "/home/books", client: client)
            XCTAssertEqual(book.title, "Book 1")
            XCTAssertEqual(book.path, "/home/books")
        }
    }
    
    func testBookGetById() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            
            let book = try await self.create(title: "Book 1", path: "/home/books", client: client)
            let _ = try await self.create(title: "Book 2", path: "/home/books", client: client)
            
            let returnedBook = try await self.get(id: book.id, client: client)
            XCTAssertEqual(returnedBook?.title, book.title)
        }
    }
    
    func testGetBookWithInvalidIdReturnsBadRequest() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            
            try await client.execute(uri: "/books/invalid", method: .get) { response in
                XCTAssertEqual(response.status, .badRequest)
            }
        }
    }
    
    func testBookGetAll() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            
            for count in 0..<10 {
                let _ = try await self.create(title: "Book \(count)", path: "/home/books", client: client)
            }
            
            let allBooks = try await self.list(client: client)
            XCTAssertEqual(allBooks.count, 10)
        }
    }
    
    func testBookPatch() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            
            let book = try await self.create(title: "Book 2", path: "/home/books", client: client)
            
            _ = try await self.patch(id: book.id, title: "Book 2 Patched", client: client)
            let editedBook = try await self.get(id: book.id, client: client)
            XCTAssertEqual(editedBook?.title, "Book 2 Patched")
            
            _ = try await self.patch(id: book.id, path: "/home/books/patched", client: client)
            let editedBook2 = try await self.get(id: book.id, client: client)
            XCTAssertEqual(editedBook2?.path, "/home/books/patched")
            // revert it
            _ = try await self.patch(id: book.id, title: "Book 2", path: "/home/books", client: client)
            let editedBook3 = try await self.get(id: book.id, client: client)
            XCTAssertEqual(editedBook3?.title, "Book 2")
            XCTAssertEqual(editedBook3?.path, "/home/books")
        }
    }
    
    func testBookPatchWithInvalidIdReturnsBadRequest() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            
            let request = UpdateRequest(title: "Book 1", path: "/home/books")
            let buffer = try JSONEncoder().encodeAsByteBuffer(request, allocator: ByteBufferAllocator())
            
            try await client.execute(uri: "/books/invalid", method: .patch, body: buffer) { response in
                XCTAssertEqual(response.status, .badRequest)
            }
        }
    }
    
    func testBookDelete() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            
            let book = try await self.create(title: "Book 2", path: "/home/books", client: client)
            let status = try await self.delete(id: book.id, client: client)
            XCTAssertEqual(status, .ok)
        }
    }
    
    func testBookDeleteTwiceReturnsBadrequest() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            
            let book = try await self.create(title: "Book 2", path: "/home/books", client: client)
            let status = try await self.delete(id: book.id, client: client)
            XCTAssertEqual(status, .ok)
            
            let status2 = try await self.delete(id: book.id, client: client)
            XCTAssertEqual(status2, .badRequest)
        }
    }
    
    func testBookDeleteAll() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            
            for count in 0..<10 {
                let _ = try await self.create(title: "Book \(count)", path: "/home/books", client: client)
            }
            
            let allBooks = try await self.list(client: client)
            XCTAssertEqual(allBooks.count, 10)
            
            let status = try await self.deleteAll(client: client)
            XCTAssertEqual(status, .ok)
            
            let afterDelete = try await self.list(client: client)
            XCTAssertEqual(afterDelete.count, 0)
        }
    }
}
