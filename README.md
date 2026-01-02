# new-menubar-app

SwiftUI로 만든 **가장 단순한 macOS Menu Bar App 템플릿**입니다.  
UI는 SwiftUI로 구성하고, 메뉴바 아이콘과 팝오버는 AppKit(NSStatusBar + NSPopover)을 사용합니다.

본 프로젝트는 **Cursor(또는 VS Code) 중심 개발**을 전제로 하며,  
Xcode는 프로젝트 생성·서명·최초 실행에만 최소한으로 사용합니다.

---

## 프로젝트 목적

- macOS 메뉴바 전용 앱의 **최소 구조 이해**
- SwiftUI + AppKit 혼합 구조 학습
- Xcode 의존도를 낮춘 개발 워크플로우 확립
- 개인용 또는 내부용 메뉴바 유틸리티 기반 템플릿 확보

---

## 기술 스택

- **Language**: Swift
- **UI**: SwiftUI
- **macOS API**: AppKit (NSStatusBar, NSPopover)
- **IDE**: Cursor (권장), Xcode (최소 사용)
- **Build Tool**: xcodebuild

---

## 프로젝트 구조

```text
new-menubar-app/
├── new-menubar-app.xcodeproj
├── AppDelegate.swift
├── PopoverView.swift
├── new_menubar_appApp.swift
├── Info.plist
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

## 환경 변수 설정

API 키나 시크릿 정보가 필요한 경우 `.env` 파일을 사용할 수 있습니다.

1. 프로젝트 루트에 `.env` 파일 생성
2. 필요한 API 키를 설정 (예시):
   ```
   BINANCE_API_KEY=your_key_here
   UPBIT_ACCESS_KEY=your_key_here
   ```
3. `.env` 파일은 `.gitignore`에 포함되어 Git에 커밋되지 않습니다

**주의**: `.env` 파일은 절대 Git에 커밋하지 마세요!
