//
//  File.swift
//  
//
//  Created by Oliver Krakora on 13.09.22.
//

import Foundation

struct Trip: Identifiable, Decodable {

    let uuid: String

    var id: String {
        return uuid
    }
}
