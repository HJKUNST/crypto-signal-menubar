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
            print("[LOADING] 초기 가격 데이터 로딩 시작...")
            do {
                let quotes = try await fetchAll()
                print("[SUCCESS] 가격 데이터 로딩 완료: \(quotes.count)개 토큰")
                onUpdate?(quotes)
            } catch {
                print("[ERROR] 가격 가져오기 실패: \(error.localizedDescription)")
            }
            
            // 이후 주기적으로 갱신
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: pollSeconds * 1_000_000_000)
                print("[LOADING] 가격 데이터 갱신 시작...")
                do {
                    let quotes = try await fetchAll()
                    print("[SUCCESS] 가격 데이터 갱신 완료: \(quotes.count)개 토큰")
                    onUpdate?(quotes)
                } catch {
                    // 네트워크 오류 등: UI를 그대로 두거나 "…" 표시로 처리 가능
                    print("[ERROR] 가격 가져오기 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func fetchAll() async throws -> [Quote] {
        // 상위 10개 토큰 중 USDT, USDC를 제외한 Binance 토큰들
        let binanceCoins = Coin.dropdownCoins.filter { $0 != .usdt && $0 != .usdc }
        var binanceSymbols = binanceCoins.map { $0.binanceSymbol }
        
        // USDC의 USD 가격도 가져오기 위해 추가
        binanceSymbols.append("USDCUSDT")
        
        print("[LOADING] Binance API에서 \(binanceSymbols.count)개 토큰 가격 가져오는 중...")
        // Binance에서 병렬로 가격 가져오기
        let binancePrices = try await binance.fetchPrices(symbols: binanceSymbols)
        print("[LOADING] Binance 가격 로딩 완료: \(binancePrices.count)개")
        
        print("[LOADING] Upbit API에서 USDT/KRW, USDC/KRW 가격 가져오는 중...")
        // USDT, USDC는 업비트에서 KRW 가격 가져오기
        let upbitTickers = try await upbit.fetchTickers(markets: ["KRW-USDT", "KRW-USDC"])
        guard let usdtTicker = upbitTickers.first(where: { $0.market == "KRW-USDT" }) else {
            throw URLError(.cannotParseResponse)
        }
        guard let usdcTicker = upbitTickers.first(where: { $0.market == "KRW-USDC" }) else {
            throw URLError(.cannotParseResponse)
        }
        print("[LOADING] Upbit USDT 가격 로딩 완료: ₩\(String(format: "%.0f", usdtTicker.trade_price))")
        print("[LOADING] Upbit USDC 가격 로딩 완료: ₩\(String(format: "%.0f", usdcTicker.trade_price))")
        
        print("[LOADING] USD/KRW 환율 가져오는 중...")
        // 환율 가져오기 (캐시 포함)
        let usdKRW = try await fx.getUSDKRW(cacheSeconds: 1800)
        print("[LOADING] 환율 로딩 완료: ₩\(String(format: "%.2f", usdKRW))/USD")
        
        // USDT 김치프리미엄 계산
        let usdtPremium = tetherPremiumPercent(usdtKRW: usdtTicker.trade_price, usdKRW: usdKRW)
        print("[LOADING] USDT 김치프리미엄 계산 완료: \(formatPremiumPercent(usdtPremium))")
        
        // USDC Spread 계산
        guard let usdcUSD = binancePrices["USDCUSDT"] else {
            throw URLError(.cannotParseResponse)
        }
        let usdcSpread = usdcSpreadPercent(usdcKRW: usdcTicker.trade_price, usdcUSD: usdcUSD, usdKRW: usdKRW)
        print("[LOADING] USDC Spread 계산 완료: \(formatPremiumPercent(usdcSpread))")
        
        // 모든 코인에 대해 Quote 생성
        var quotes: [Quote] = []
        
        print("[LOADING] 가격 데이터 처리 중...")
        // Binance 토큰들
        for coin in binanceCoins {
            let symbol = coin.binanceSymbol
            guard let price = binancePrices[symbol] else { continue }
            let quote = updateTrend(coin: coin, newPrice: price, premiumPercent: nil)
            quotes.append(quote)
        }
        
        // USDT
        let usdt = updateTrend(coin: .usdt, newPrice: usdtTicker.trade_price, premiumPercent: usdtPremium)
        quotes.append(usdt)
        
        // USDC
        let usdc = updateTrend(coin: .usdc, newPrice: usdcTicker.trade_price, premiumPercent: usdcSpread)
        quotes.append(usdc)
        
        // 드롭다운 순서대로 정렬
        let sortedQuotes = quotes.sorted { quote1, quote2 in
            let index1 = Coin.dropdownCoins.firstIndex(of: quote1.coin) ?? Int.max
            let index2 = Coin.dropdownCoins.firstIndex(of: quote2.coin) ?? Int.max
            return index1 < index2
        }

        return sortedQuotes
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
