# new-menubar-app

macOS 메뉴바에서 실시간 암호화폐 가격을 표시하는 앱입니다.  
BTC, ETH, USDT 가격을 표시하고, USDT 김치프리미엄을 계산하여 보여줍니다.

---

## 주요 기능

- **실시간 가격 표시**
  - BTC, ETH: Binance API에서 USD 가격 조회
  - USDT: Upbit API에서 KRW 가격 조회
- **김치프리미엄 계산**: USDT의 업비트 가격과 환율을 비교하여 프리미엄(%) 표시
- **가격 변화 표시**: 상승(↗︎, green), 하락(↘︎, red), 변화 없음(–)
- **백그라운드 실행**: Dock 아이콘 없이 메뉴바에서만 실행
- **자동 갱신**: 2분마다 자동으로 가격 갱신

---

## 기술 스택

- **Language**: Swift
- **UI**: AppKit (NSStatusBar)
- **API**:
  - Binance API (BTC, ETH USD 가격)
  - Upbit API (USDT KRW 가격)
  - exchangerate-api.com (USD/KRW 환율)
- **IDE**: Cursor (권장), Xcode
- **Build Tool**: xcodebuild

---

## 프로젝트 구조

```text
new-menubar-app/
├── new-menubar-app.xcodeproj
├── new-menubar-app/
│   ├── AppDelegate.swift          # 앱 초기화 및 백그라운드 실행 설정
│   ├── StatusBarUI.swift          # 메뉴바 UI 렌더링
│   ├── PricePollingService.swift  # 가격 폴링 및 추세 계산
│   ├── BinanceClient.swift        # Binance API 클라이언트
│   ├── UpbitClient.swift          # Upbit API 클라이언트
│   ├── ExchangeRateClient.swift   # 환율 API 클라이언트
│   ├── ExchangeRateService.swift  # 환율 캐싱 서비스
│   ├── Models.swift                # 데이터 모델 및 유틸리티 함수
│   ├── new_menubar_appApp.swift   # SwiftUI App 진입점
│   ├── Assets.xcassets/           # 코인 아이콘 이미지
│   └── new-menubar-app.entitlements
└── README.md
```

## Terminal에서 빌드 & 실행

### 스킴 확인

```text
xcodebuild -list
```

### 빌드

```
xcodebuild \
  -scheme "new-menubar-app" \
  -configuration Debug \
  -derivedDataPath "./DerivedData" \
  build
```

### 실행

```
open "./DerivedData/Build/Products/Debug/new-menubar-app.app"
```

## 메뉴바 표시 형식

```
₿ $12345.67 ↗︎   Ξ $2345.67 ↘︎   ₮ ₩1350.50 (+0.25%) ↗︎
```

- **아이콘**: 각 코인의 아이콘 이미지
- **BTC/ETH**: USD 가격 (Binance 기준)
- **USDT**: KRW 가격 + 김치프리미엄(%) (Upbit 기준)
- **화살표**: 가격 변화 방향 (↗︎=green, ↘︎=red, –=기본색)

---

## 환경 변수 설정

현재는 공개 API를 사용하므로 API 키가 필요하지 않습니다.  
향후 API 키가 필요한 경우 `.env` 파일을 사용할 수 있습니다.

1. 프로젝트 루트에 `.env` 파일 생성
2. 필요한 API 키를 설정 (예시):
   ```
   BINANCE_API_KEY=your_key_here
   UPBIT_ACCESS_KEY=your_key_here
   ```
3. `.env` 파일은 `.gitignore`에 포함되어 Git에 커밋되지 않습니다

**주의**: `.env` 파일은 절대 Git에 커밋하지 마세요!

---

## 설정

### 가격 갱신 주기 변경

`AppDelegate.swift`의 `service.start(pollSeconds: 120)`에서 주기를 변경할 수 있습니다.

- 30초: `service.start(pollSeconds: 30)`
- 1분: `service.start(pollSeconds: 60)`
- 5분: `service.start(pollSeconds: 300)`

### 환율 캐시 시간 변경

`PricePollingService.swift`의 `fx.getUSDKRW(cacheSeconds: 1800)`에서 캐시 시간을 변경할 수 있습니다.

- 10분: `cacheSeconds: 600`
- 30분: `cacheSeconds: 1800` (기본값)
