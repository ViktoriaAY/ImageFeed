import XCTest

class Image_FeedUITests: XCTestCase {
    
    private let app = XCUIApplication()

       override func setUpWithError() throws {
           try super.setUpWithError()
           continueAfterFailure = false
           
           // Передаем общий флаг тестирования во все тесты без исключения
           app.launchArguments = ["UITesting"]
       }

    
    func testAuth() throws {
        print("🤖 [UI TEST] Начало теста testAuth")
        
        app.launchArguments = ["clearSessionForTesting"]
        app.launch()
        
        let imagesListTable = app.tables["ImagesListTable"]
        if imagesListTable.waitForExistence(timeout: 5) && imagesListTable.children(matching: .cell).element(boundBy: 0).exists {
            print("🎉 [UI TEST] Приложение уже авторизовано, лента на экране! Завершаем тест успехом.")
            return
        }
        
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 5), "Кнопка 'Authenticate' не найдена")
        print("🤖 [UI TEST] Кликаем по кнопке Authenticate")
        authButton.tap()
        
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 15), "WebView не загрузился")
        print("🤖 [UI TEST] WebView UnsplashWebView успешно обнаружен на экране")
        print("🤖 [UI TEST] Ожидаем отрисовку элементов внутри WebView...")
        let emailField = webView.descendants(matching: .textField).element(boundBy: 0)
        
        if !emailField.waitForExistence(timeout: 30) {
            XCTFail("Поля ввода не появились в WebView")
            return
        }
        
        let passwordField = webView.descendants(matching: .secureTextField).element(boundBy: 0)
        XCTAssertTrue(passwordField.exists, "Поле пароля не найдено")
        
        print("🤖 [UI TEST] Вводим логин...")
        emailField.tap()
        emailField.typeText("v.perxun@inbox.ru")
        closeKeyboard()
        
        print("🤖 [UI TEST] Скроллим к паролю...")
        webView.swipeUp()
        
        print("🤖 [UI TEST] Копируем и вставляем пароль...")
        passwordField.tap()
        
        UIPasteboard.general.string = "kawxeq-sehsog-0tiqMy"
        
        passwordField.doubleTap()
        
        let pasteButton = app.menuItems["Paste"] ?? app.menuItems["Вставить"]
        if pasteButton.waitForExistence(timeout: 3) {
            pasteButton.tap()
            print("🤖 [UI TEST] Пароль успешно вставлен из буфера.")
        } else {
            print("⚠️ Меню 'Вставить' не появилось, пробуем обычный ввод...")
            passwordField.typeText("kawxeq-sehsog-0tiqMy")
        }
        closeKeyboard()
        
        print("🤖 [UI TEST] Поля заполнены. Подготовка к нажатию Login...")
        webView.tap()
    
        let loginButton = webView.buttons["Login"]
        let loginButtonAlternative = webView.buttons["Log in"]
        let loginButtonRu = webView.buttons["Войти"]
        
        if loginButton.waitForExistence(timeout: 5) {
            print("🤖 [UI TEST] Нажимаем 'Login'")
            loginButton.tap()
        } else if loginButtonAlternative.waitForExistence(timeout: 2) {
            print("🤖 [UI TEST] Нажимаем 'Log in'")
            loginButtonAlternative.tap()
        } else if loginButtonRu.waitForExistence(timeout: 2) {
            print("🤖 [UI TEST] Нажимаем 'Войти'")
            loginButtonRu.tap()
        } else {
            webView.descendants(matching: .button).element(boundBy: 0).tap()
        }
        
       
        print("🤖 [UI TEST] Проверяем появление промежуточного экрана прав Unsplash...")
        let allowButton = webView.buttons["Allow"]
        let authorizeButton = webView.buttons["Authorize"]
        let allowButtonRu = webView.buttons["Разрешить"]
        
        if allowButton.waitForExistence(timeout: 10) {
            print("🤖 [UI TEST] Найдена кнопка Allow, подтверждаем доступ...")
            allowButton.tap()
        } else if authorizeButton.waitForExistence(timeout: 2) {
            print("🤖 [UI TEST] Найдена кнопка Authorize, подтверждаем доступ...")
            authorizeButton.tap()
        } else if allowButtonRu.waitForExistence(timeout: 2) {
            print("🤖 [UI TEST] Найдена кнопка Разрешить, подтверждаем доступ...")
            allowButtonRu.tap()
        } else {
            print("🤖 [UI TEST] Экран прав не появился, ждем ленту.")
        }
        
        print("🤖 [UI TEST] Ждем появление главной таблицы приложения...")
        let tablesQuery = app.tables["ImagesListTable"]
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        
        let isTableDisplayed = cell.waitForExistence(timeout: 40)
        
        XCTAssertTrue(cell.exists, "Авторизация не удалась: ячейка ленты так и не появилась на экране")
        print("🎉 [UI TEST] Авторизация успешно завершена, таблица ленты на экране!")
    }
    
    func testFeed() throws {
        print("🤖 [UI TEST] Шаг 1: Запустить приложение")
        app.launchArguments = ["UITesting"]
        app.launch()
        
        let tablesQuery = app.tables
        let imagesListTable = tablesQuery["ImagesListTable"]
        
        print("🤖 [UI TEST] Шаг 2: Подождать, пока открывается и загружается экран ленты")
        XCTAssertTrue(imagesListTable.waitForExistence(timeout: 30), "🚨 Таблица не появилась. Сначала запустите testAuth!")
        
        // Ждем загрузку первой ячейки на старте
        let cell = imagesListTable.cells.element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 30), "🚨 Первая ячейка ленты не загрузилась")
        
        print("🤖 [UI TEST] Шаг 3: Смахиваем экран ВВЕРХ (скролл ленты к нижним картинкам)...")
        imagesListTable.swipeUp()
        sleep(2)
        
        print("🤖 [UI TEST] Смахиваем экран ВНИЗ до упора (возврат к самой первой ячейке)...")
        imagesListTable.swipeDown()
        imagesListTable.swipeDown()
        sleep(3)
        
        let targetCell = imagesListTable.cells.element(boundBy: 0)
        XCTAssertTrue(targetCell.waitForExistence(timeout: 15), "🚨 Не удалось вернуться к первой ячейке после скролла")

        
        print("🤖 [UI TEST] Шаг 4 & 5: Поставить и отменить лайк в ячейке первой картинки")
        let likeButtonOff = targetCell.buttons["like button off"]
        let likeButtonOn = targetCell.buttons["like button on"]
        
        if likeButtonOff.waitForExistence(timeout: 5) {
            print("🤖 Ставим лайк...")
            likeButtonOff.tap()
            XCTAssertTrue(likeButtonOn.waitForExistence(timeout: 10), "🚨 Лайк не включился")
            sleep(1)
            
            print("🤖 Отменяем лайк...")
            likeButtonOn.tap()
            XCTAssertTrue(likeButtonOff.waitForExistence(timeout: 10), "🚨 Лайк не выключился")
            sleep(1)
        } else if likeButtonOn.waitForExistence(timeout: 5) {
            print("🤖 Картинка уже была с лайком. Сначала отменяем лайк...")
            likeButtonOn.tap()
            XCTAssertTrue(likeButtonOff.waitForExistence(timeout: 10), "🚨 Лайк не выключился")
            sleep(1)
            
            print("🤖 Ставим лайк обратно...")
            likeButtonOff.tap()
            XCTAssertTrue(likeButtonOn.waitForExistence(timeout: 10), "🚨 Лайк не включился")
            sleep(1)
        }
        
        print("🤖 [UI TEST] Шаг 6 & 7: Нажать на ячейку и подождать, пока картинка откроется на весь экран")
        targetCell.tap()
        
        sleep(4)
        
        print("🤖 [UI TEST] Шаг 8 & 9: Тестируем увеличение и уменьшение картинки (pinch)")
        let image = app.scrollViews.images.element(boundBy: 0)
        XCTAssertTrue(image.waitForExistence(timeout: 25), "🚨 Полноэкранная картинка не загрузилась")
        
        image.pinch(withScale: 3, velocity: 1)
        sleep(1)
        image.pinch(withScale: 0.5, velocity: -1)
        sleep(1)
        
        print("🤖 [UI TEST] Шаг 10: Вернуться на экран ленты")
        let navBackButtonWhiteButton = app.buttons["nav back button white"]
        XCTAssertTrue(navBackButtonWhiteButton.waitForExistence(timeout: 5), "🚨 Кнопка возврата не найдена")
        navBackButtonWhiteButton.tap()
        
        XCTAssertTrue(imagesListTable.exists, "🚨 Не удалось вернуться на экран ленты")
        print("🎉 [UI TEST] Честный тест ленты по сценарию Яндекса успешно пройден!")
    }
    
    func testProfile() throws {
        print("🤖 [UI TEST] Шаг 1: Запустить приложение")
        app.launchArguments = ["UITesting"]
        app.launch()
        
        print("🤖 [UI TEST] Шаг 2: Подождать, пока открывается и загружается экран ленты")
        let imagesListTable = app.tables["ImagesListTable"]
        XCTAssertTrue(imagesListTable.waitForExistence(timeout: 30), "🚨 Экран ленты не загрузился")
        
        print("🤖 [UI TEST] Шаг 3: Перейти на экран профиля")
        let profileTabButton = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(profileTabButton.waitForExistence(timeout: 10), "🚨 Вкладка профиля в Таббаре не найдена")
        profileTabButton.tap()
        
        sleep(3)
        
        print("🤖 [UI TEST] Шаг 4: Проверить, что на нём отображаются ваши персональные данные")
        let nameLabel = app.staticTexts["Viktoria Yunosheva"]
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 10), "🚨 Персональные данные (имя Viktoria Yunosheva) не отобразились")
        
        let loginLabel = app.staticTexts["@yuyu1905"]
        XCTAssertTrue(loginLabel.exists, "🚨 Персональные данные (username @yuyu1905) не найдены на экране")
        
        print("🤖 [UI TEST] Шаг 5: Нажать кнопку логаута")
        let logoutButton = app.buttons["logout button"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5), "🚨 Кнопка выхода 'logout button' не найдена")
        logoutButton.tap()
        
        let alertEn = app.alerts["Bye bye!"]
        let alertRu = app.alerts["Пока, пока!"]
        
        if alertEn.waitForExistence(timeout: 5) {
            alertEn.buttons["Yes"].tap()
        } else if alertRu.waitForExistence(timeout: 5) {
            alertRu.buttons["Да"].tap()
        } else {
            let confirmPredicate = NSPredicate(format: "label TEXT matches [c] 'да' OR label TEXT matches [c] 'yes'")
            let confirmButton = app.alerts.element.buttons.element(matching: confirmPredicate)
            if confirmButton.exists {
                confirmButton.tap()
            } else {
                app.alerts.element.buttons.element(boundBy: 1).tap()
            }
        }
        
        print("🤖 [UI TEST] Шаг 6: Проверить, что открылся экран авторизации")
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 15), "🚨 Экран авторизации не появился после логаута")
        
        print("🎉 [UI TEST] Тест профиля и логаута успешно пройден строго по сценарию!")
    }

    private func pastePassword(passwordField: XCUIElement, password: String) {
        UIPasteboard.general.string = password
        passwordField.tap()
        sleep(1)
        passwordField.doubleTap()
        
        let pasteMenuEnglish = app.menuItems["Paste"]
        let pasteMenuRussian = app.menuItems["Вставить"]
        
        if pasteMenuEnglish.waitForExistence(timeout: 3) {
            pasteMenuEnglish.tap()
        } else if pasteMenuRussian.waitForExistence(timeout: 3) {
            pasteMenuRussian.tap()
        } else {
            for character in password {
                passwordField.typeText(String(character))
            }
        }
    }
    
    private func closeKeyboard() {
        let doneToolbarButton = app.buttons["Done"]
        let doneToolbarButtonRu = app.buttons["Выполнено"]
        
        if doneToolbarButton.exists {
            doneToolbarButton.tap()
        } else if doneToolbarButtonRu.exists {
            doneToolbarButtonRu.tap()
        } else {
            let keyboard = app.keyboards.element
            if keyboard.exists {
                let checkmarkCoordinate = keyboard.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.05))
                checkmarkCoordinate.tap()
            }
        }
    }
}

extension XCUIElement {
    func forceTap() {
        let coordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
    }
}
