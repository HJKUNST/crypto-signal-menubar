//
//  AppDelegate.swift
//  new-menubar-app
//
//  Created by 김희주 on 1/2/26.
//

import Cocoa

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let ui = StatusBarUI()
    private let service = PricePollingService()
    private var lastQuotes: [Quote] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 백그라운드 실행 설정: 마지막 윈도우가 닫혀도 앱이 종료되지 않도록
        NSApp.setActivationPolicy(.accessory)
        
        // 가격 업데이트 콜백 설정
        service.onUpdate = { [weak self] quotes in
            self?.lastQuotes = quotes
            self?.ui.render(quotes: quotes)
        }
        
        // pinned 토큰 변경 시 UI 업데이트
        ui.onPinnedTokensChanged = { [weak self] in
            guard let self = self else { return }
            self.ui.render(quotes: self.lastQuotes)
        }
        
        // 표시 모드 변경 시 UI 업데이트
        ui.onDisplayModeChanged = { [weak self] in
            guard let self = self else { return }
            self.ui.render(quotes: self.lastQuotes)
        }

        // 2분(120초)마다 가격 갱신
        service.start(pollSeconds: 120)
    }

    func applicationWillTerminate(_ notification: Notification) {
        service.stop()
        }
    }