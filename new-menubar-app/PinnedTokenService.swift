//
//  PinnedTokenService.swift
//  new-menubar-app
//
//  Created by 김희주 on 1/2/26.
//

import Foundation

@MainActor
final class PinnedTokenService {
    private let userDefaults = UserDefaults.standard
    private let pinnedKey = "pinnedTokens"
    
    // 기본값: BTC, ETH, USDT
    private let defaultPinned: [Coin] = [.btc, .eth, .usdt]
    
    // 현재 pinned된 토큰들
    var pinnedTokens: [Coin] {
        get {
            guard let data = userDefaults.data(forKey: pinnedKey),
                  let strings = try? JSONDecoder().decode([String].self, from: data) else {
                return defaultPinned
            }
            return strings.compactMap { Coin(rawValue: $0) }
        }
        set {
            let strings = newValue.map { $0.rawValue }
            if let data = try? JSONEncoder().encode(strings) {
                userDefaults.set(data, forKey: pinnedKey)
            }
        }
    }
    
    // 토큰을 pinned 상태로 토글
    // 최소 1개, 최대 3개 제한
    func togglePinned(_ coin: Coin) -> Bool {
        var current = pinnedTokens
        
        if let index = current.firstIndex(of: coin) {
            // 이미 pinned된 경우: 제거 (단, 최소 1개는 유지)
            if current.count > 1 {
                current.remove(at: index)
                pinnedTokens = current
                return true
            } else {
                // 최소 1개는 유지해야 함
                return false
            }
        } else {
            // pinned되지 않은 경우: 추가 (단, 최대 3개까지만)
            if current.count < 3 {
                current.append(coin)
                pinnedTokens = current
                return true
            } else {
                // 최대 3개 초과
                return false
            }
        }
    }
    
    // 특정 토큰이 pinned되어 있는지 확인
    func isPinned(_ coin: Coin) -> Bool {
        return pinnedTokens.contains(coin)
    }
}
