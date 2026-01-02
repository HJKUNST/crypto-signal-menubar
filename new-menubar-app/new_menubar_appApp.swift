//
//  new_menubar_appApp.swift
//  new-menubar-app
//
//  Created by 김희주 on 1/2/26.
//

import SwiftUI

@main
struct YourAppNameApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 설정 창을 비워서 기본 WindowGroup을 만들지 않습니다.
        Settings {
            EmptyView()
        }
    }
}
