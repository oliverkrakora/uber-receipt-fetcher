//
//  File.swift
//  
//
//  Created by Oliver Krakora on 13.09.22.
//

import Foundation

extension URLSession {
    func performRequest<T: Decodable>(request: URLRequest, decoder: JSONDecoder = JSONDecoder(), type: T.Type = T.self) async throws -> (T, HTTPURLResponse) {
        let (data, response) = try await data(for: request)
        let decoded = try decoder.decode(T.self, from: data)
        return (decoded, response as! HTTPURLResponse)
    }

    func performDownload(request: URLRequest, destination: URL) async throws {
        let (downloadURL, response) = try await download(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: URLError.errorDomain, code: URLError.resourceUnavailable.rawValue)
        }
        try FileManager.default.moveItem(at: downloadURL, to: destination)
    }
}
