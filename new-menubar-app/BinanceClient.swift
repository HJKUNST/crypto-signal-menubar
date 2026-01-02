//
//  BinanceClient.swift
//  new-menubar-app
//
//  Created by 김희주 on 1/2/26.
//

import Foundation

final class BinanceClient {
    struct TickerPrice: Decodable {
        let symbol: String
        let price: String
    }

    func fetchPrice(symbol: String) async throws -> Double {
        var comps = URLComponents(string: "https://api.binance.com/api/v3/ticker/price")!
        comps.queryItems = [URLQueryItem(name: "symbol", value: symbol)]
        let url = comps.url!

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(TickerPrice.self, from: data)
        guard let p = Double(decoded.price) else { throw URLError(.cannotParseResponse) }
        return p
    }
}
