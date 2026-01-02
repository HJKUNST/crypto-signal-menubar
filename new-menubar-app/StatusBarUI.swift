//
//  StatusBarUI.swift
//  new-menubar-app
//
//  Created by 김희주 on 1/2/26.
//

import Cocoa

final class StatusBarUI {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    init() {
        // 초기 표시
        statusItem.button?.title = "BTC ... | ETH ... | USDT ..."
        
        // 메뉴 설정
        let menu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApplication.shared
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    func render(quotes: [Quote]) {
        // 모든 코인을 하나의 attributed string으로 합치기
        let attributedStrings = quotes.map { formatAttributed($0) }
        let combined = NSMutableAttributedString()
        
        for attrStr in attributedStrings {
            combined.append(attrStr)
            combined.append(NSAttributedString(string: "   "))  // 요소 간 gap 증가
        }
        
        statusItem.button?.attributedTitle = combined
    }

    private func formatAttributed(_ q: Quote) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // 아이콘 이미지 추가
        if let iconImage = NSImage(named: q.coin.imageName) {
            // 이미지 크기를 작게 조정 (12x12)
            iconImage.size = NSSize(width: 12, height: 12)
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = iconImage
            // 가운데 정렬을 위해 y 오프셋 조정
            imageAttachment.bounds = CGRect(x: 0, y: -2, width: 12, height: 12)
            let imageString = NSAttributedString(attachment: imageAttachment)
            result.append(imageString)
            result.append(NSAttributedString(string: " "))
        }
        
        // 가격 포맷팅
        let priceText: String
        if q.coin == .usdt {
            // USDT는 원화 기호(₩) 추가
            priceText = "₩" + String(format: "%.0f", q.price)
        } else {
            // BTC, ETH는 USD로 표시 (천 단위 구분자와 소수점 2자리)
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            priceText = "$" + (formatter.string(from: NSNumber(value: q.price)) ?? String(format: "%.2f", q.price))
        }
        
        // 레이아웃: (icon)(price)(김프%)(arrow) - ticker 제거
        var text = priceText
        
        // USDT일 때만 김치프리미엄 표시 (괄호로 감싸기)
        if q.coin == .usdt, let premium = q.premiumPercent {
            text += " (" + formatPremiumPercent(premium) + ")"
        }
        
        text += " "
        
        // 화살표 색상 설정
        let arrowColor: NSColor
        switch q.trend {
        case .up:
            arrowColor = .systemGreen
        case .down:
            arrowColor = .systemRed
        case .flat:
            arrowColor = .labelColor
        }
        
        // 텍스트 추가 (화살표 제외)
        result.append(NSAttributedString(string: text, attributes: [.foregroundColor: NSColor.labelColor]))
        
        // 화살표 추가 (색상 적용)
        result.append(NSAttributedString(string: q.trend.symbol, attributes: [.foregroundColor: arrowColor]))
        
        return result
    }
}
