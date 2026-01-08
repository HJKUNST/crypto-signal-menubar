# new-menubar-app

macOS 메뉴바에서 실시간 암호화폐 가격을 표시하는 앱입니다.  
상위 10개 암호화폐 가격을 표시하고, USDT/USDC의 김치프리미엄/Spread를 계산하여 보여줍니다.

---

## 주요 기능

### 실시간 가격 표시

- **상위 10개 토큰 지원**: BTC, ETH, BNB, SOL, XRP, USDC, USDT, DOGE, ADA, TRX
- **가격 소스**:
  - BTC, ETH, BNB, SOL, XRP, DOGE, ADA, TRX: Binance API에서 USD 가격 조회
  - USDT, USDC: Upbit API에서 KRW 가격 조회
- **김치프리미엄/Spread 계산**: USDT와 USDC의 업비트 가격과 환율을 비교하여 프리미엄(%) 표시

### 표시 모드

- **Pinned Mode**: 사용자가 선택한 토큰들(최소 1개, 최대 3개)을 메뉴바에 고정 표시
- **Auto Mode (Carousel)**: 모든 토큰을 3초마다 자동으로 순환 표시 (세로 회전 애니메이션)

### 기타 기능

- **가격 변화 표시**: 상승(↗︎, green), 하락(↘︎, red), 변화 없음(–)
- **백그라운드 실행**: Dock 아이콘 없이 메뉴바에서만 실행
- **자동 갱신**: 2분마다 자동으로 가격 갱신
- **드롭다운 메뉴**: 메뉴바 클릭 시 상위 10개 토큰 전체 가격 확인 가능

---

## 기술 스택

- **Language**: Swift
- **UI**: AppKit (NSStatusBar, NSMenu)
- **Animation**: QuartzCore (CATransition)
- **API**:
  - Binance API (BTC, ETH, BNB, SOL, XRP, DOGE, ADA, TRX USD 가격, USDC USD 가격)
  - Upbit API (USDT, USDC KRW 가격)
  - exchangerate-api.com (USD/KRW 환율)
- **Storage**: UserDefaults (pinned 토큰, 표시 모드 저장)
- **IDE**: Cursor (권장), Xcode
- **Build Tool**: xcodebuild

---

## 프로젝트 구조

```text
new-menubar-app/
├── new-menubar-app.xcodeproj
├── new-menubar-app/
│   ├── AppDelegate.swift          # 앱 초기화 및 백그라운드 실행 설정
│   ├── StatusBarUI.swift          # 메뉴바 UI 렌더링 (Pinned/Auto 모드)
│   ├── PricePollingService.swift  # 가격 폴링 및 추세 계산
│   ├── PinnedTokenService.swift   # Pinned 토큰 관리 (UserDefaults)
│   ├── DisplayModeService.swift   # 표시 모드 관리 (UserDefaults)
│   ├── BinanceClient.swift        # Binance API 클라이언트
│   ├── UpbitClient.swift          # Upbit API 클라이언트
│   ├── ExchangeRateClient.swift   # 환율 API 클라이언트
│   ├── ExchangeRateService.swift  # 환율 캐싱 서비스
│   ├── Models.swift                # 데이터 모델 및 유틸리티 함수
│   ├── new_menubar_appApp.swift   # SwiftUI App 진입점
│   ├── Assets.xcassets/           # 코인 아이콘 이미지 (10개)
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

## 사용 방법

### 표시 모드 선택

1. 메뉴바 아이콘 클릭
2. "Display Mode" → "Pinned Mode" 또는 "Auto Mode (Carousel)" 선택

### Pinned Mode

- 메뉴에서 원하는 토큰 클릭하여 메뉴바에 고정 (최소 1개, 최대 3개)
- 고정된 토큰은 체크마크(✓)로 표시
- 예시: `₿ $12345.67 ↗︎   Ξ $2345.67 ↘︎   ₮ ₩1350.50 (+0.25%) ↗︎`

### Auto Mode (Carousel)

- 모든 토큰이 3초마다 자동으로 순환 표시
- 세로 회전 애니메이션 효과
- 예시: `₿ $12345.67 ↗︎` → (3초 후) → `Ξ $2345.67 ↘︎` → (3초 후) → ...

## 메뉴바 표시 형식

### Pinned Mode 예시

```
₿ $12345.67 ↗︎   Ξ $2345.67 ↘︎   ₮ ₩1350.50 (+0.25%) ↗︎
```

### Auto Mode 예시

```
₿ $12345.67 ↗︎
```

(3초 후 자동 전환)

### 표시 형식 설명

- **아이콘**: 각 코인의 아이콘 이미지
- **BTC, ETH, BNB, SOL, XRP, DOGE, ADA, TRX**: USD 가격 (Binance 기준)
- **USDT, USDC**: KRW 가격 + 김치프리미엄/Spread(%) (Upbit 기준)
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
- 2분: `service.start(pollSeconds: 120)` (기본값)
- 5분: `service.start(pollSeconds: 300)`

### 환율 캐시 시간 변경

`PricePollingService.swift`의 `fx.getUSDKRW(cacheSeconds: 1800)`에서 캐시 시간을 변경할 수 있습니다.

- 10분: `cacheSeconds: 600`
- 30분: `cacheSeconds: 1800` (기본값)

### Auto Mode Carousel 간격 변경

`StatusBarUI.swift`의 `carouselInterval`에서 Carousel 전환 간격을 변경할 수 있습니다.

- 2초: `private let carouselInterval: TimeInterval = 2.0`
- 3초: `private let carouselInterval: TimeInterval = 3.0` (기본값)
- 5초: `private let carouselInterval: TimeInterval = 5.0`

---

## 지원 토큰

현재 지원하는 토큰 목록:

| 토큰 | 가격 소스 | 표시 형식     |
| ---- | --------- | ------------- |
| BTC  | Binance   | USD           |
| ETH  | Binance   | USD           |
| BNB  | Binance   | USD           |
| SOL  | Binance   | USD           |
| XRP  | Binance   | USD           |
| USDC | Upbit     | KRW + 김프(%) |
| USDT | Upbit     | KRW + 김프(%) |
| DOGE | Binance   | USD           |
| ADA  | Binance   | USD           |
| TRX  | Binance   | USD           |

---

## 로그

앱 실행 시 콘솔에 다음과 같은 로그가 출력됩니다:

- `[LOADING]`: 데이터 로딩 중
- `[SUCCESS]`: 성공적으로 완료
- `[ERROR]`: 오류 발생
- `[INFO]`: 정보 메시지

로그를 통해 가격 갱신 상태와 오류를 확인할 수 있습니다.
