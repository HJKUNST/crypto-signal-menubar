//
//  StatusBarUI.swift
//  new-menubar-app
//
//  Created by 김희주 on 1/2/26.
//

import Cocoa
import QuartzCore
import os.log

@MainActor
final class StatusBarUI {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var allQuotes: [Quote] = []  // 드롭다운용 전체 가격 저장
    private let pinnedService = PinnedTokenService()
    private let displayModeService = DisplayModeService()
    private let logger = Logger(subsystem: "com.new-menubar-app", category: "StatusBarUI")
    
    var onPinnedTokensChanged: (() -> Void)?  // pinned 토큰 변경 시 콜백
    var onDisplayModeChanged: (() -> Void)?  // 표시 모드 변경 시 콜백
    
    // Carousel 관련
    private var carouselTimer: Timer?
    private var currentCarouselIndex: Int = 0
    private let carouselInterval: TimeInterval = 3.0  // 3초마다 전환
    private let animationDuration: TimeInterval = 0.5  // 애니메이션 지속 시간
    
    init() {
        // 초기 표시
        statusItem.button?.title = "Loading..."
        
        // 메뉴 설정
        updateMenu()
        
        // auto 모드일 때 carousel 시작
        if displayModeService.currentMode == .auto {
            startCarousel()
        }
    }
    
    deinit {
        // deinit은 nonisolated이므로 직접 invalidate (thread-safe)
        carouselTimer?.invalidate()
        carouselTimer = nil
    }

    func render(quotes: [Quote]) {
        logger.info("[UI] render() 호출됨 - \(quotes.count)개 토큰")
        print("[UI] render() 호출됨 - \(quotes.count)개 토큰")
        
        // 드롭다운용 전체 가격 저장 (먼저 업데이트하여 메뉴에서 최신 가격 사용)
        allQuotes = quotes
        
        // 메뉴 업데이트 (드롭다운 메뉴의 가격 정보 갱신) - 최신 quotes 사용
        updateMenu(quotes: quotes)
        
        // 표시 모드에 따라 다르게 렌더링
        switch displayModeService.currentMode {
        case .pinned:
            logger.info("[UI] Pinned 모드로 렌더링")
            print("[UI] Pinned 모드로 렌더링")
            renderPinnedMode(quotes: quotes)
        case .auto:
            logger.info("[UI] Auto 모드로 렌더링")
            print("[UI] Auto 모드로 렌더링")
            renderAutoMode(quotes: quotes, animated: false)
            // auto mode일 때 carousel이 시작되어 있지 않으면 시작
            if carouselTimer == nil {
                startCarousel()
            }
        }
        
        logger.info("[UI] render() 완료")
        print("[UI] render() 완료")
    }
    
    private func renderPinnedMode(quotes: [Quote]) {
        // 메뉴바에 표시할 코인만 필터링 (pinned된 토큰들)
        let pinnedCoins = pinnedService.pinnedTokens
        let menuBarQuotes = quotes.filter { pinnedCoins.contains($0.coin) }
        
        guard !menuBarQuotes.isEmpty else {
            // pinned 토큰에 대한 가격이 아직 로드되지 않은 경우
            statusItem.button?.attributedTitle = NSAttributedString(string: "Loading...")
            return
        }
        
        // 모든 코인을 하나의 attributed string으로 합치기
        let attributedStrings = menuBarQuotes.map { formatAttributed($0) }
        let combined = NSMutableAttributedString()
        
        for (index, attrStr) in attributedStrings.enumerated() {
            combined.append(attrStr)
            // 마지막 요소가 아니면 gap 추가
            if index < attributedStrings.count - 1 {
                combined.append(NSAttributedString(string: "   "))  // 요소 간 gap
            }
        }
        
        statusItem.button?.attributedTitle = combined
    }
    
    private func renderAutoMode(quotes: [Quote], animated: Bool = false) {
        // 모든 토큰을 순서대로 정렬
        let sortedQuotes = quotes.sorted { quote1, quote2 in
            let index1 = Coin.dropdownCoins.firstIndex(of: quote1.coin) ?? Int.max
            let index2 = Coin.dropdownCoins.firstIndex(of: quote2.coin) ?? Int.max
            return index1 < index2
        }
        
        guard !sortedQuotes.isEmpty else {
            statusItem.button?.attributedTitle = NSAttributedString(string: "Loading...")
            return
        }
        
        // 현재 인덱스의 토큰만 표시
        let currentQuote = sortedQuotes[currentCarouselIndex % sortedQuotes.count]
        let newAttributedTitle = formatAttributed(currentQuote)
        
        if animated, let button = statusItem.button {
            // 세로 회전 애니메이션 적용
            animateVerticalRotation(on: button, to: newAttributedTitle)
        } else {
            statusItem.button?.attributedTitle = newAttributedTitle
        }
    }
    
    private func animateVerticalRotation(on button: NSButton, to newTitle: NSAttributedString) {
        // layer 활성화
        button.wantsLayer = true
        
        guard let layer = button.layer else {
            button.layer = CALayer()
            button.attributedTitle = newTitle
            return
        }
        
        // CATransition을 사용한 세로 회전 효과
        let transition = CATransition()
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromTop  // 위에서 아래로 회전하는 효과
        transition.duration = animationDuration
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        // 애니메이션 적용
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            // 애니메이션 완료 후 최종 텍스트 설정
            button.attributedTitle = newTitle
        }
        layer.add(transition, forKey: "verticalRotation")
        button.attributedTitle = newTitle
        CATransaction.commit()
    }
    
    private func startCarousel() {
        // auto mode가 아니면 시작하지 않음
        guard displayModeService.currentMode == .auto else { return }
        
        stopCarousel()
        
        carouselTimer = Timer.scheduledTimer(withTimeInterval: carouselInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Timer 클로저는 nonisolated이므로 Task로 감싸서 메인 스레드에서 실행
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.nextCarouselItem()
            }
        }
        
        // 타이머를 RunLoop에 추가하여 메뉴바 클릭 시에도 동작하도록
        if let timer = carouselTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopCarousel() {
        carouselTimer?.invalidate()
        carouselTimer = nil
    }
    
    private func nextCarouselItem() {
        guard displayModeService.currentMode == .auto else { return }
        guard !allQuotes.isEmpty else { return }
        
        let sortedQuotes = allQuotes.sorted { quote1, quote2 in
            let index1 = Coin.dropdownCoins.firstIndex(of: quote1.coin) ?? Int.max
            let index2 = Coin.dropdownCoins.firstIndex(of: quote2.coin) ?? Int.max
            return index1 < index2
        }
        
        guard !sortedQuotes.isEmpty else { return }
        
        currentCarouselIndex = (currentCarouselIndex + 1) % sortedQuotes.count
        // 애니메이션과 함께 렌더링
        renderAutoMode(quotes: allQuotes, animated: true)
    }
    
    private func updateMenu(quotes: [Quote]? = nil) {
        // 최신 quotes를 사용 (파라미터가 없으면 allQuotes 사용)
        let currentQuotes = quotes ?? allQuotes
        
        let menu = NSMenu()
        
        // 표시 모드 선택 메뉴
        let modeMenu = NSMenu()
        
        let pinnedModeItem = NSMenuItem(title: "Pinned Mode", action: #selector(selectPinnedMode(_:)), keyEquivalent: "")
        pinnedModeItem.target = self
        pinnedModeItem.state = displayModeService.currentMode == .pinned ? .on : .off
        modeMenu.addItem(pinnedModeItem)
        
        let autoModeItem = NSMenuItem(title: "Auto Mode (Carousel)", action: #selector(selectAutoMode(_:)), keyEquivalent: "")
        autoModeItem.target = self
        autoModeItem.state = displayModeService.currentMode == .auto ? .on : .off
        modeMenu.addItem(autoModeItem)
        
        let modeSubmenuItem = NSMenuItem(title: "Display Mode", action: nil, keyEquivalent: "")
        modeSubmenuItem.submenu = modeMenu
        menu.addItem(modeSubmenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 상위 10개 토큰 메뉴 아이템 추가
        for coin in Coin.dropdownCoins {
            if let quote = currentQuotes.first(where: { $0.coin == coin }) {
                let menuItem = createMenuItem(for: quote)
                menu.addItem(menuItem)
            } else {
                // 아직 가격이 로드되지 않은 경우
                let menuItem = NSMenuItem(title: "\(coin.rawValue) Loading...", action: nil, keyEquivalent: "")
                menuItem.isEnabled = false
                menu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 안내 메시지 (pinned 모드일 때만)
        if displayModeService.currentMode == .pinned {
            let infoItem = NSMenuItem(title: "클릭하여 메뉴바에 고정 (최소 1개, 최대 3개)", action: nil, keyEquivalent: "")
            infoItem.isEnabled = false
            menu.addItem(infoItem)
        } else {
            let infoItem = NSMenuItem(title: "Auto 모드: 모든 토큰이 3초마다 순환 표시됩니다", action: nil, keyEquivalent: "")
            infoItem.isEnabled = false
            menu.addItem(infoItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit 메뉴
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApplication.shared
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc private func selectPinnedMode(_ sender: NSMenuItem) {
        displayModeService.currentMode = .pinned
        stopCarousel()
        currentCarouselIndex = 0
        
        // 메뉴를 먼저 업데이트하여 상태 동기화
        updateMenu()
        
        // pinned 모드로 전환 시 즉시 pinned 토큰들 표시
        if !allQuotes.isEmpty {
            render(quotes: allQuotes)
        }
        
        onDisplayModeChanged?()
    }
    
    @objc private func selectAutoMode(_ sender: NSMenuItem) {
        displayModeService.currentMode = .auto
        currentCarouselIndex = 0
        
        // 메뉴를 먼저 업데이트하여 상태 동기화
        updateMenu()
        
        // auto 모드로 전환 시 즉시 첫 번째 토큰 표시
        if !allQuotes.isEmpty {
            render(quotes: allQuotes)
        }
        
        // carousel 시작 (콜백 호출 전에 시작)
        startCarousel()
        
        // 콜백 호출 (외부에서 render를 다시 호출할 수 있지만, carousel은 이미 시작됨)
        onDisplayModeChanged?()
    }
    
    private func createMenuItem(for quote: Quote) -> NSMenuItem {
        let priceText: String
        if quote.coin == .usdt || quote.coin == .usdc {
            priceText = "₩" + String(format: "%.0f", quote.price)
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            priceText = "$" + (formatter.string(from: NSNumber(value: quote.price)) ?? String(format: "%.2f", quote.price))
        }
        
        var title = "\(quote.coin.rawValue)  \(priceText)"
        
        if (quote.coin == .usdt || quote.coin == .usdc), let premium = quote.premiumPercent {
            title += " (" + formatPremiumPercent(premium) + ")"
        }
        
        title += "  \(quote.trend.symbol)"
        
        // pinned 상태 확인
        let isPinned = pinnedService.isPinned(quote.coin)
        
        let menuItem = NSMenuItem(title: "", action: #selector(togglePinned(_:)), keyEquivalent: "")
        menuItem.target = self
        menuItem.representedObject = quote.coin
        
        // AttributedString 생성
        let attributedTitle = NSMutableAttributedString()
        
        // 1. 체크마크 추가 (아이콘 앞에, systemGray 색상)
        if isPinned {
            let checkMark = NSAttributedString(string: "✓ ", attributes: [.foregroundColor: NSColor.systemGray])
            attributedTitle.append(checkMark)
        }
        
        // 2. 아이콘 추가 (attributedTitle에 포함)
        if let iconImage = NSImage(named: quote.coin.imageName) {
            iconImage.size = NSSize(width: 16, height: 16)
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = iconImage
            imageAttachment.bounds = CGRect(x: 0, y: -3, width: 16, height: 16)
            let imageString = NSAttributedString(attachment: imageAttachment)
            attributedTitle.append(imageString)
            attributedTitle.append(NSAttributedString(string: " "))
        }
        
        // 3. 텍스트 추가
        let textString = NSAttributedString(string: title)
        let textStartIndex = attributedTitle.length
        attributedTitle.append(textString)
        
        // 4. 화살표 색상 설정
        let arrowRange = (title as NSString).range(of: quote.trend.symbol)
        if arrowRange.location != NSNotFound {
            // attributedTitle에서 화살표 위치 계산 (텍스트 시작 위치 + 화살표 위치)
            let arrowStartIndex = textStartIndex + arrowRange.location
            // 범위 검증
            if arrowStartIndex + arrowRange.length <= attributedTitle.length {
                let arrowColor: NSColor
                switch quote.trend {
                case .up:
                    arrowColor = .systemGreen
                case .down:
                    arrowColor = .systemRed
                case .flat:
                    arrowColor = .labelColor
                }
                attributedTitle.addAttribute(.foregroundColor, value: arrowColor, range: NSRange(location: arrowStartIndex, length: arrowRange.length))
            }
        }
        
        // 5. Auto mode일 때 메뉴 너비 제한 (폰트 크기 줄이기 및 paragraph style 적용)
        if displayModeService.currentMode == .auto {
            // 폰트 크기를 약간 줄여서 메뉴 너비 감소
            let font = NSFont.systemFont(ofSize: 12)
            attributedTitle.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedTitle.length))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byTruncatingTail
            paragraphStyle.maximumLineHeight = 16
            attributedTitle.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedTitle.length))
        }
        
        menuItem.attributedTitle = attributedTitle
        
        return menuItem
    }
    
    @objc private func togglePinned(_ sender: NSMenuItem) {
        // pinned 모드일 때만 토글 가능
        guard displayModeService.currentMode == .pinned else { return }
        
        guard let coin = sender.representedObject as? Coin else { return }
        
        let success = pinnedService.togglePinned(coin)
        if success {
            // UI 업데이트 (pinned 토큰 변경 반영) - 먼저 호출하여 메뉴바에 즉시 반영
            onPinnedTokensChanged?()
            // 메뉴 업데이트 (드롭다운 메뉴의 체크마크 상태 업데이트)
            updateMenu()
        } else {
            // 제한 메시지 표시 (선택사항)
            let message: String
            if pinnedService.pinnedTokens.count >= 3 {
                message = "최대 3개까지만 선택할 수 있습니다."
            } else {
                message = "최소 1개는 선택해야 합니다."
            }
            print("[INFO] \(message)")
        }
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
        if q.coin == .usdt || q.coin == .usdc {
            // USDT, USDC는 원화 기호(₩) 추가
            priceText = "₩" + String(format: "%.0f", q.price)
        } else {
            // BTC, ETH 등은 USD로 표시 (천 단위 구분자와 소수점 2자리)
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            priceText = "$" + (formatter.string(from: NSNumber(value: q.price)) ?? String(format: "%.2f", q.price))
        }
        
        // 레이아웃: (icon)(price)(spread%)(arrow) - ticker 제거
        var text = priceText
        
        // USDT, USDC일 때 spread/premium 표시 (괄호로 감싸기)
        if (q.coin == .usdt || q.coin == .usdc), let premium = q.premiumPercent {
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
