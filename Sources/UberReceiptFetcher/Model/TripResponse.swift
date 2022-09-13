//
//  File.swift
//  
//
//  Created by Oliver Krakora on 13.09.22.
//

import Foundation

struct TripResponse: Decodable {

    private enum CodingKeys: String, CodingKey {
        case data
        case getTrips
        case count
        case pagingResult
        case trips
    }

    let count: Int
    let trips: [Trip]
    let paging: Paging

    init(from decoder: Decoder) throws {
        var container = try decoder.container(keyedBy: CodingKeys.self)
        container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .getTrips)
        self.count = try container.decode(Int.self, forKey: .count)
        self.trips = try container.decode([Trip].self, forKey: .trips)
        self.paging = try container.decode(Paging.self, forKey: .pagingResult)
    }
}
