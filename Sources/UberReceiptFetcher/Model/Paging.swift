//
//  File.swift
//  
//
//  Created by Oliver Krakora on 13.09.22.
//

import Foundation

struct Paging: Decodable {
    let hasMore: Bool
    let nextCursor: String?
}
