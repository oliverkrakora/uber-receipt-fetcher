//
//  File.swift
//  
//
//  Created by Oliver Krakora on 13.09.22.
//

import Foundation
import ArgumentParser

struct YearMonthDayDate: ExpressibleByArgument {

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-y"
        return formatter
    }()

    let date: Date

    init?(argument: String) {
        guard let date = Self.formatter.date(from: argument) else { return nil }
        self.date = date
    }
}
