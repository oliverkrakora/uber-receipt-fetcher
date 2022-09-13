//
//  File.swift
//  
//
//  Created by Oliver Krakora on 13.09.22.
//

import Foundation

struct Trip: Identifiable, Decodable {

    enum Status: String, Decodable {
        case completed = "COMPLETED"
        case canceled = "CANCELED"
    }

    let uuid: String
    let status: Status

    var id: String {
        return uuid
    }
}
