//
//  PricePollingService.swift
//  new-menubar-app
//
//  Created by 김희주 on 1/2/26.
//

import Foundation

@MainActor
final class PricePollingService {
    private let binance = BinanceClient()
    private let upbit = UpbitClient()
    private let fx = ExchangeRateService()

    // 직전 가격 저장 (추세 계산용)
    private var lastPrice: [Coin: Double] = [:]

    // 외부에서 UI 업데이트를 받기 위한 콜백
    var onUpdate: (([Quote]) -> Void)?

    // 폴링 제어
    private var task: Task<Void, Never>?

    func start(pollSeconds: UInt64) {
        stop()

        task = Task {
            // 즉시 첫 번째 가격 가져오기
            do {
                let quotes = try await fetchAll()
                onUpdate?(quotes)
            } catch {
                print("가격 가져오기 실패: \(error.localizedDescription)")
            }
            
            // 이후 주기적으로 갱신
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: pollSeconds * 1_000_000_000)
                do {
                    let quotes = try await fetchAll()
                    onUpdate?(quotes)
                } catch {
                    // 네트워크 오류 등: UI를 그대로 두거나 "…" 표시로 처리 가능
                    print("가격 가져오기 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func fetchAll() async throws -> [Quote] {
        // BTC, ETH는 Binance에서 USD 가격 가져오기
        let btcPrice = try await binance.fetchPrice(symbol: "BTCUSDT")
        let ethPrice = try await binance.fetchPrice(symbol: "ETHUSDT")
        
        // USDT는 업비트에서 KRW 가격 가져오기
        let usdtTickers = try await upbit.fetchTickers(markets: ["KRW-USDT"])
        guard let usdtTicker = usdtTickers.first(where: { $0.market == "KRW-USDT" }) else {
            throw URLError(.cannotParseResponse)
        }
        
        // 환율 가져오기 (캐시 포함)
        let usdKRW = try await fx.getUSDKRW(cacheSeconds: 1800)
        
        // 김치프리미엄 계산
        let premium = tetherPremiumPercent(usdtKRW: usdtTicker.trade_price, usdKRW: usdKRW)
        
        let btc = updateTrend(coin: .btc, newPrice: btcPrice, premiumPercent: nil)
        let eth = updateTrend(coin: .eth, newPrice: ethPrice, premiumPercent: nil)
        let usdt = updateTrend(coin: .usdt, newPrice: usdtTicker.trade_price, premiumPercent: premium)

        return [btc, eth, usdt]
    }

    private func updateTrend(coin: Coin, newPrice: Double, premiumPercent: Double?) -> Quote {
        let prev = lastPrice[coin]

        let trend: Trend
        if let prev {
            if newPrice > prev { trend = .up }
            else if newPrice < prev { trend = .down }
            else { trend = .flat }
        } else {
            trend = .flat
        }

        lastPrice[coin] = newPrice
        return Quote(coin: coin, price: newPrice, trend: trend, premiumPercent: premiumPercent)
    }
}
