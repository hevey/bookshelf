//
//  BookDTO.swift
//  Bookshelf
//
//  Created by Glenn Hevey on 31/8/2024.
//

import Fluent
import Vapor

struct BookDTO: Content {
    var id: UUID?
    var title: String?
    var path: String?
    
    func toModel() -> Book {
        let model = Book()
        
        model.id = id
        if let title = title {
            model.title = title
        }
        
        if let path = path {
            model.path = path
        }
        
        return model
    }
}
