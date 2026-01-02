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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 백그라운드 실행 설정: 마지막 윈도우가 닫혀도 앱이 종료되지 않도록
        NSApp.setActivationPolicy(.accessory)
        
        // 가격 업데이트 콜백 설정
        service.onUpdate = { [weak self] quotes in
            self?.ui.render(quotes: quotes)
        }

        // 2분(120초)마다 가격 갱신
        service.start(pollSeconds: 120)
    }

    func applicationWillTerminate(_ notification: Notification) {
        service.stop()
    }
}