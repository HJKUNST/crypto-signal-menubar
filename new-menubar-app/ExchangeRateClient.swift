//
//  ExchangeRateClient.swift
//  new-menubar-app
//
//  Created by 김희주 on 1/2/26.
//

import Foundation

struct ExchangeRateResponse: Decodable {
    let base: String
    let rates: [String: Double]
    let date: String?
}

final class ExchangeRateClient {
    func fetchUSDKRW() async throws -> Double {
        // exchangerate-api.com 사용 (무료, API 키 불필요)
        let url = URL(string: "https://api.exchangerate-api.com/v4/latest/USD")!
        let (data, resp) = try await URLSession.shared.data(from: url)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        guard let rate = decoded.rates["KRW"] else { throw URLError(.cannotParseResponse) }
        return rate
    }
}
