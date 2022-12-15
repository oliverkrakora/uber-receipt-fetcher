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
    let outputDir: URL

    init(baseURL: URL, cookie: String) {
        self.urlSession = URLSession.shared
        self.baseURL = baseURL
        self.cookie = cookie
        self.outputDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: false)
    }

    func fetchReceipts(from: Date?, to: Date?) async throws {

        for try await receiptPage in receiptStream(from: from, to: to) {
            try await downloadReceipts(inResponse: receiptPage)
        }
    }
}

// MARK: Helpers
private extension ReceiptFetcher {

    func downloadReceipts(inResponse response: TripResponse) async throws {

        await withThrowingTaskGroup(of: Void.self) { group in
            for trip in response.trips where trip.status == .completed {
                group.addTask {
                    let downloadURL = self.generateReceiptURL(forTrip: trip.id)
                    let outputURL = self.outputDir.appendingPathComponent(trip.id).appendingPathExtension("pdf")
                    var request = URLRequest(url: downloadURL)
                    self.authorizeRequest(request: &request)
                    try await self.urlSession.performDownload(request: request, destination: outputURL)
                }
            }
        }
    }

    func receiptStream(from: Date?, to: Date?) -> AsyncThrowingStream<TripResponse, Error> {
        return AsyncThrowingStream { continuation in
            let task = Task.detached {
                var response: TripResponse? = nil

                while (response?.paging.hasMore ?? true) && !Task.isCancelled {
                    do {
                        let request = self.createFetchReceiptsRequest(from: from, to: to, cursor: response?.paging.nextCursor)
                        let res = try await self.urlSession.performRequest(request: request, type: TripResponse.self)
                        response = res.0
                        continuation.yield(res.0)
                    } catch {
                        continuation.yield(with: .failure(error))
                    }
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func createFetchReceiptsRequest(from: Date?, to: Date?, cursor: String?) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent("graphql"))
        request.httpMethod = "POST"
        authorizeRequest(request: &request)
        request.httpBody = createFetchReceiptsGraphQLQuery(from: from, to: to, cursor: cursor).data(using: .utf8)!
        return request
    }

    func authorizeRequest(request: inout URLRequest) {
        request.addValue(cookie, forHTTPHeaderField: "Cookie")
        request.addValue("x", forHTTPHeaderField: "X-Csrf-Token")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    func createFetchReceiptsGraphQLQuery(from: Date?, to: Date?, cursor: String?) -> String {
        let fromInMilli = from.flatMap { "\(Int($0.timeIntervalSince1970) * 1000)" } ?? "null"
        let toInMilli = to.flatMap { "\(Int($0.timeIntervalSince1970) * 1000)" } ?? "null"

        let query = """
{"operationName":"GetTrips","variables":{"cursor":"\(cursor.flatMap { "\($0)" } ?? "")","fromTime": \(fromInMilli),"toTime": \(toInMilli)},"query":"query GetTrips($cursor: String, $fromTime: Float, $toTime: Float) {\\n  getTrips(cursor: $cursor, fromTime: $fromTime, toTime: $toTime) {\\n    count\\n    pagingResult {\\n      hasMore\\n      nextCursor\\n      __typename\\n    }\\n    reservations {\\n      ...TripFragment\\n      __typename\\n    }\\n    trips {\\n      ...TripFragment\\n      __typename\\n    }\\n    __typename\\n  }\\n}\\n\\nfragment TripFragment on Trip {\\n  beginTripTime\\n  disableCanceling\\n  driver\\n  dropoffTime\\n  fare\\n  isRidepoolTrip\\n  isScheduledRide\\n  isSurgeTrip\\n  isUberReserve\\n  jobUUID\\n  marketplace\\n  paymentProfileUUID\\n  status\\n  uuid\\n  vehicleDisplayName\\n  waypoints\\n  __typename\\n}\\n"}
"""
        return query
    }

    func generateReceiptURL(forTrip tripId: Trip.ID) -> URL {
        let url = baseURL.appendingPathComponent("trips/\(tripId)/receipt")
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "contentType", value: "PDF")]
        return urlComponents.url!
    }
}
