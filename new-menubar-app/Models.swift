//
//  Models.swift
//  new-menubar-app
//
//  Created by 김희주 on 1/2/26.
//

import Foundation

enum Coin: String {
    case btc = "BTC"
    case eth = "ETH"
    case bnb = "BNB"
    case sol = "SOL"
    case xrp = "XRP"
    case usdc = "USDC"
    case usdt = "USDT"
    case doge = "DOGE"
    case ada = "ADA"
    case trx = "TRX"
    
    var imageName: String {
        switch self {
        case .btc: return "btc"
        case .eth: return "eth"
        case .bnb: return "bnb"
        case .sol: return "sol"
        case .xrp: return "xrp"
        case .usdc: return "usdc"
        case .usdt: return "usdt"
        case .doge: return "doge"
        case .ada: return "ada"
        case .trx: return "tron"
        }
    }
    
    // Binance 심볼 (USDT 마켓)
    var binanceSymbol: String {
        return rawValue + "USDT"
    }
    
    // 드롭다운에 표시할 코인 (상위 10개)
    static var dropdownCoins: [Coin] {
        return [.btc, .eth, .bnb, .sol, .xrp, .usdc, .usdt, .doge, .ada, .trx]
    }
}

enum Trend {
    case up, down, flat

    var symbol: String {
        switch self {
        case .up: return "↗︎"
        case .down: return "↘︎"
        case .flat: return "–"
        }
    }
}

struct Quote {
    let coin: Coin
    let price: Double
    let trend: Trend
    let premiumPercent: Double?  // USDT, USDC일 때 사용 (spread)
}

// 김치프리미엄/Spread 계산 함수
func tetherPremiumPercent(usdtKRW: Double, usdKRW: Double) -> Double {
    guard usdKRW > 0 else { return 0 }
    // 1 USDT ≈ 1 USD 가정
    let theoretical = usdKRW
    return (usdtKRW - theoretical) / theoretical * 100
}

// USDC Spread 계산 함수 (KRW 가격과 USD 가격 비교)
func usdcSpreadPercent(usdcKRW: Double, usdcUSD: Double, usdKRW: Double) -> Double {
    guard usdcUSD > 0, usdKRW > 0 else { return 0 }
    // 이론적 KRW 가격 = USD 가격 * USD/KRW 환율
    let theoreticalKRW = usdcUSD * usdKRW
    return (usdcKRW - theoreticalKRW) / theoreticalKRW * 100
}

func formatPremiumPercent(_ value: Double) -> String {
    // +0.00% 형태
    return String(format: "%+.2f%%", value)
}
