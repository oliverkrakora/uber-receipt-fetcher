//
//  main.swift
//  
//
//  Created by Oliver Krakora on 13.09.22.
//

import Foundation
import ArgumentParser

// https://github.com/apple/swift-argument-parser/blob/d52044c091d2c02986dfd8c4ef183076ea2dc876/Sources/ArgumentParser/Documentation.docc/Extensions/AsyncParsableCommand.md
@main struct UberReceiptFetcher: ParsableCommand, AsyncParsableCommand {

    @Option(help: "The oldest date where to stop fetching")
    var startDate: YearMonthDayDate?

    @Option(help: "The most recent date from where to start fetching")
    var endDate: YearMonthDayDate?

    @Argument(help: "The cookie from you web browser session")
    var cookie: String

    mutating func run() async throws {
        let url = URL(string: "https://riders.uber.com")!
        let fetcher = ReceiptFetcher(baseURL: url, cookie: cookie)
        try await fetcher.fetchReceipts(from: startDate?.date,
                                        to: endDate?.date)
    }
}
