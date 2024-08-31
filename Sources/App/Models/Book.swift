import Foundation
import Fluent

final class Book: Model, @unchecked Sendable {
    static let schema = "books"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String
    
    @Field(key: "path")
    var path: String
    
    init() { }

    init(id: UUID? = nil, title: String, path: String) {
        self.id = id
        self.title = title
        self.path = path
    }
    
    func toDTO() -> BookDTO {
        .init(
            id: self.id,
            title: self.$title.value,
            path: self.$path.value
        )
    }
}
