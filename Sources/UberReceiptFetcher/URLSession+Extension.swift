//
//  File.swift
//  
//
//  Created by Oliver Krakora on 13.09.22.
//

import Foundation

extension URLSession {
    func performRequest<T: Decodable>(request: URLRequest, decoder: JSONDecoder = JSONDecoder(), type: T.Type = T.self) async throws -> (T, URLResponse) {
        let (data, response) = try await data(for: request)
        let decoded = try decoder.decode(T.self, from: data)
        return (decoded, response)
    }

    @discardableResult
    func performDownload(request: URLRequest, destination: URL) async throws -> URLResponse {
        let (downloadURL, response) = try await download(for: request)
        try FileManager.default.moveItem(at: downloadURL, to: destination)
        return response
    }
}
