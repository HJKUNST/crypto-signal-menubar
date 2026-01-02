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
    case usdt = "USDT"
    
    var imageName: String {
        switch self {
        case .btc: return "btc"
        case .eth: return "eth"
        case .usdt: return "usdt"
        }
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
    let premiumPercent: Double?  // USDT일 때만 사용
}

// 김치프리미엄 계산 함수
func tetherPremiumPercent(usdtKRW: Double, usdKRW: Double) -> Double {
    guard usdKRW > 0 else { return 0 }
    // 1 USDT ≈ 1 USD 가정
    let theoretical = usdKRW
    return (usdtKRW - theoretical) / theoretical * 100
}

func formatPremiumPercent(_ value: Double) -> String {
    // +0.00% 형태
    return String(format: "%+.2f%%", value)
}
