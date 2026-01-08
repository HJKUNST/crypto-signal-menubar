//
//  DisplayModeService.swift
//  new-menubar-app
//
//  Created by 김희주 on 1/2/26.
//

import Foundation

enum DisplayMode: String, Codable {
    case pinned  // 고정된 토큰들 표시
    case auto    // 자동으로 모든 토큰 순환 표시
}

@MainActor
final class DisplayModeService {
    private let userDefaults = UserDefaults.standard
    private let modeKey = "displayMode"
    
    // 현재 표시 모드
    var currentMode: DisplayMode {
        get {
            guard let data = userDefaults.data(forKey: modeKey),
                  let mode = try? JSONDecoder().decode(DisplayMode.self, from: data) else {
                return .pinned  // 기본값: pinned
            }
            return mode
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: modeKey)
            }
        }
    }
    
    // 모드 토글
    func toggleMode() -> DisplayMode {
        let newMode: DisplayMode = currentMode == .pinned ? .auto : .pinned
        currentMode = newMode
        return newMode
    }
}
