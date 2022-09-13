//
//  ReceiptFetcher.swift
//  
//
//  Created by Oliver Krakora on 13.09.22.
//

import Foundation

class ReceiptFetcher {

    private let urlSession: URLSession
    private let baseURL: URL
    private let cookie: String
    private let outputDir: URL

    init(baseURL: URL, cookie: String) {
        self.urlSession = URLSession.shared
        self.baseURL = baseURL
        self.cookie = cookie
        self.outputDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: false)
    }

    func fetchReceipts(from: Date?, to: Date?) async throws {

        for try await receiptPage in receiptPageStream(from: from, to: to) {
            try await downloadReceipts(inResponse: receiptPage)
        }
    }
}

// MARK: Helpers
private extension ReceiptFetcher {

    func downloadReceipts(inResponse response: TripResponse) async throws {

        await withThrowingTaskGroup(of: Void.self) { group in
            for trip in response.trips {
                group.addTask {
                    let downloadURL = self.generateReceiptURL(forTrip: trip.id)
                    let outputURL = self.outputDir.appendingPathComponent(trip.id)
                    var request = URLRequest(url: downloadURL)
                    self.authorizeRequest(request: &request)
                    try await self.urlSession.performDownload(request: request, destination: outputURL)
                }
            }
        }
    }

    func receiptPageStream(from: Date?, to: Date?) -> AsyncThrowingStream<TripResponse, Error> {
        return AsyncThrowingStream { continuation in
            Task.detached {
                var response: TripResponse? = nil

                while response?.paging.hasMore ?? true {
                    do {
                        let request = self.createFetchReceiptsRequest(from: from, to: to, cursor: response?.paging.nextCursor)
                        let res = try await self.urlSession.performRequest(request: request, type: TripResponse.self)
                        response = res.0
                        continuation.yield(res.0)
                    } catch {
                        continuation.yield(with: .failure(error))
                    }
                }
            }
        }
    }

    func createFetchReceiptsRequest(from: Date?, to: Date?, cursor: Int?) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent("graphql"))
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        authorizeRequest(request: &request)
        request.httpBody = createFetchReceiptsGraphQLQuery(from: from, to: to, cursor: cursor).data(using: .utf8)!
        return request
    }

    func authorizeRequest(request: inout URLRequest) {
        request.addValue(cookie, forHTTPHeaderField: "Cookie")
        request.addValue("x", forHTTPHeaderField: "X-Csrf-Token")
    }

    func createFetchReceiptsGraphQLQuery(from: Date?, to: Date?, cursor: Int?) -> String {
        let fromInterval = from?.timeIntervalSince1970
        let toInterval = to?.timeIntervalSince1970

        let query = """
{"operationName":"GetTrips","variables":{"cursor":"\(cursor.flatMap { "\($0)" } ?? "")","fromTime": "\(fromInterval.flatMap { "\($0)" } ?? "null")","toTime":"\(toInterval.flatMap { "\($0)" } ?? "null")"},"query":"query GetTrips($cursor: String, $fromTime: Float, $toTime: Float) {\n  getTrips(cursor: $cursor, fromTime: $fromTime, toTime: $toTime) {\n    count\n    pagingResult {\n      hasMore\n      nextCursor\n      __typename\n    }\n    reservations {\n      ...TripFragment\n      __typename\n    }\n    trips {\n      ...TripFragment\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment TripFragment on Trip {\n  beginTripTime\n  disableCanceling\n  driver\n  dropoffTime\n  fare\n  isRidepoolTrip\n  isScheduledRide\n  isSurgeTrip\n  isUberReserve\n  jobUUID\n  marketplace\n  paymentProfileUUID\n  status\n  uuid\n  vehicleDisplayName\n  waypoints\n  __typename\n}\n"}
"""
        return query
    }

    func generateReceiptURL(forTrip tripId: Trip.ID) -> URL {
        return baseURL.appendingPathComponent("trips/\(tripId)/receipt")
    }
}
