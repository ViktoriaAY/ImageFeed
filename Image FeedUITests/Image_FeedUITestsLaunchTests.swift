//
//  Image_FeedUITestsLaunchTests.swift
//  Image FeedUITests
//
//  Created by Виктория Юношева on 19.08.2026.
//

import XCTest


final class Image_FeedUITestsLaunchTests: XCTestCase {
    
    private let app = XCUIApplication()

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
            try super.setUpWithError()
            continueAfterFailure = false
            
            // 1. Флаг тестирования передаем всегда
            app.launchArguments.append("isUITesting")
            
            if name.contains("testAuth") {
                // 2. ДЛЯ ТЕСТА АВТОРИЗАЦИИ: принудительно очищаем окружение и просим стереть сессию
                app.launchArguments.append("clearSessionForTesting")
                app.launchEnvironment.removeValue(forKey: "TEST_TOKEN")
            } else {
                // 3. ДЛЯ ОСТАЛЬНЫХ ТЕСТОВ (Лента, Профиль): передаем токен
                let myActualToken = "ВАШ_РЕАЛЬНЫЙ_Bearer_ТОКЕН_ИЗ_КОНСОЛИ"
                app.launchEnvironment["TEST_TOKEN"] = myActualToken
            }
            
            app.launch()
        }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
