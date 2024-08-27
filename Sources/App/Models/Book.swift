//
//  File.swift
//  Bookshelf
//
//  Created by Glenn Hevey on 26/8/2024.
//

import Foundation
import Hummingbird

struct Book {
    var id: UUID
    var title: String
    var path: String
    
    var author: String?
    var publisher: String?
    var description: String?
    var isbn: Int?
    var doi: String?
}

extension Book: ResponseEncodable, Decodable, Equatable {}
