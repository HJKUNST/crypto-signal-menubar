//
//  ExchangeRateService.swift
//  new-menubar-app
//
//  Created by 김희주 on 1/2/26.
//

import Foundation

@MainActor
final class ExchangeRateService {
    private let client = ExchangeRateClient()
    private var cachedRate: Double?
    private var lastFetchedAt: Date?

    /// cacheSeconds 예: 600(10분) ~ 1800(30분)
    func getUSDKRW(cacheSeconds: TimeInterval) async throws -> Double {
        let now = Date()
        if let rate = cachedRate,
           let last = lastFetchedAt,
           now.timeIntervalSince(last) < cacheSeconds {
            return rate
        }

        let rate = try await client.fetchUSDKRW()
        cachedRate = rate
        lastFetchedAt = now
        return rate
    }
}
