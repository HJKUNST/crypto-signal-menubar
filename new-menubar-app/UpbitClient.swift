//
//  UpbitClient.swift
//  new-menubar-app
//
//  Created by 김희주 on 1/2/26.
//

import Foundation

final class UpbitClient {
    struct Ticker: Decodable {
        let market: String
        let trade_price: Double
        // 필요하면 signed_change_rate / signed_change_price 등도 추가 가능
    }

    /// 예: markets = ["KRW-BTC", "KRW-ETH", "KRW-USDT"]
    func fetchTickers(markets: [String]) async throws -> [Ticker] {
        var comps = URLComponents(string: "https://api.upbit.com/v1/ticker")!
        comps.queryItems = [
            URLQueryItem(name: "markets", value: markets.joined(separator: ","))
        ]
        let url = comps.url!

        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([Ticker].self, from: data)
    }
}
