import XCTest

class Image_FeedUITests: XCTestCase {
    private let app = XCUIApplication()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        // Сбрасываем сессию ТОЛЬКО для первого теста авторизации.
        // Остальные тесты (Feed, Profile) запустятся в текущем состоянии, используя этот же вход.
        if name.contains("testAuth") {
            app.launchArguments.append("isUITesting")
        }
        
        app.launch()
    }

//    // --- ТЕСТ 1: НАСТОЯЩАЯ АВТОРИЗАЦИЯ ---
//    func testAuth() throws {
//        let authButton = app.buttons["Authenticate"]
//        
//        // Если тест перезапустился и мы уже внутри — пропускаем шаг ввода
//        if !authButton.waitForExistence(timeout: 5) && app.tables.element(boundBy: 0).exists {
//            return
//        }
//        
//        XCTAssertTrue(authButton.waitForExistence(timeout: 5), "Кнопка 'Authenticate' не найдена")
//        authButton.tap()
//            
//        let webView = app.webViews["UnsplashWebView"]
//        XCTAssertTrue(webView.waitForExistence(timeout: 15), "WebView не загрузился")
//        
//        // Даём сайту 3 секунды отрисовать HTML-код полей
//        sleep(3)
//
//        let emailField = webView.descendants(matching: .textField).element(boundBy: 0)
//        let passwordField = webView.descendants(matching: .secureTextField).element(boundBy: 0)
//        
//        XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Поле email не найдено")
//        XCTAssertTrue(passwordField.waitForExistence(timeout: 5), "Поле пароля не найдено")
//        
//        // Вводим логин
//        emailField.tap()
//        emailField.typeText("v.perxun@inbox.ru")
//        closeKeyboard() // Закрываем клавиатуру по черной галочке над ней [3NNcp0]
//        
//        // Скроллим к паролю, так как клавиатура скрылась и не мешает
//        webView.swipeUp()
//        
//        // Вставляем пароль через копирование
//        pastePassword(passwordField: passwordField, password: "kawxeq-sehsog-0tiqMy")
//        closeKeyboard() // Снова закрываем клавиатуру [3NNcp0]
//        
//        // Нажимаем честную кнопку Login
//        let loginButton = webView.buttons["Login"]
//        if loginButton.waitForExistence(timeout: 5) {
//            loginButton.tap()
//        } else {
//            webView.descendants(matching: .button).element(boundBy: 0).tap()
//        }
//        
//        // Ждем появления таблицы приложения (теперь WebView не зависнет!)
//        let tablesQuery = app.tables
//        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
//        XCTAssertTrue(cell.waitForExistence(timeout: 30), "Авторизация не удалась: ячейка ленты не появилась")
//    }
    
    func testAuth() throws {
        print("🤖 [UI TEST] Начало теста testAuth")
        
        let authButton = app.buttons["Authenticate"]
        if !authButton.waitForExistence(timeout: 5) && app.tables.element(boundBy: 0).exists {
            print("🤖 [UI TEST] Приложение уже авторизовано. Пропускаем шаг ввода.")
            return
        }
        
        XCTAssertTrue(authButton.waitForExistence(timeout: 5), "Кнопка 'Authenticate' не найдена")
        print("🤖 [UI TEST] Кликаем по кнопке Authenticate")
        authButton.tap()
            
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 15), "WebView не загрузился")
        print("🤖 [UI TEST] WebView UnsplashWebView успешно обнаружен на экране")
        
        sleep(3) // Ожидание прорисовки полей

        let emailField = webView.descendants(matching: .textField).element(boundBy: 0)
        let passwordField = webView.descendants(matching: .secureTextField).element(boundBy: 0)
        
        XCTAssertTrue(emailField.waitForExistence(timeout: 20), "Поле email не найдено")
        XCTAssertTrue(passwordField.waitForExistence(timeout: 20), "Поле пароля не найдено")
        
        print("🤖 [UI TEST] Вводим логин...")
        emailField.tap()
        emailField.typeText("v.perxun@inbox.ru")
        closeKeyboard()
        
        print("🤖 [UI TEST] Скроллим к паролю...")
        webView.swipeUp()
        
        print("🤖 [UI TEST] Вставляем пароль через буфер...")
        pastePassword(passwordField: passwordField, password: "kawxeq-sehsog-0tiqMy")
        closeKeyboard()
        
        print("🤖 [UI TEST] Поля заполнены. Подготовка к нажатию Login...")
        webView.tap() // убираем фокус
        
        let loginButton = webView.buttons["Login"]
        let anyButton = webView.descendants(matching: .button).element(boundBy: 0)
        
        if loginButton.waitForExistence(timeout: 5) {
            print("🤖 [UI TEST] Нажимаем кнопку с текстом 'Login'")
            loginButton.tap()
        } else {
            print("🤖 [UI TEST] Кнопка с текстом 'Login' не найдена, нажимаем первый .button элемент в WebView")
            anyButton.tap()
        }
        
        print("🤖 [UI TEST] Клик по кнопке совершен. Ждем реакцию WebView и появление таблицы приложения...")
        
        // --- ДИАГНОСТИЧЕСКИЙ БЛОК ОЖИДАНИЯ ---
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        
        let exists = cell.waitForExistence(timeout: 70)
        
        if !exists {
            print("🚨 [UI TEST FAILURE DIAGNOSTIC]")
            print("🚨 Тест завис на кнопке Login. Текущее дерево элементов WebView:")
            print(webView.debugDescription)
            
            // Дополнительно проверяем, не вылез ли на экране системный алерт или ошибка
            if app.alerts.count > 0 {
                print("🚨 Обнаружен системный алерт: \(app.alerts.element(boundBy: 0).debugDescription)")
            }
        }
        
        XCTAssertTrue(cell.exists, "Авторизация не удалась: ячейка ленты так и не появилась на экране")
        print("🎉 [UI TEST] Авторизация успешно завершена, таблица ленты на экране!")
    }

    
    // --- ТЕСТ 2: ЛЕНТА (FEED) ---
    func testFeed() throws {
            let tablesQuery = app.tables
            
            // 1. Ждем загрузку первой ячейки в ленте
            let cellToLike = tablesQuery.children(matching: .cell).element(boundBy: 0)
            XCTAssertTrue(cellToLike.waitForExistence(timeout: 20), "🚨 [UI TEST ERROR]: Первая ячейка ленты не загрузилась за 20 секунд")
            
            // 2. Находим кнопку лайка прямо на первой ячейке (она точно в зоне видимости!)
            let likeButtonOff = cellToLike.buttons["like button off"]
            XCTAssertTrue(likeButtonOff.waitForExistence(timeout: 5), "🚨 [UI TEST ERROR]: Кнопка 'like button off' не найдена")
            
            // 3. Ставим лайк
            likeButtonOff.tap()
            
            // 4. Ждем, пока состояние изменится на включенный лайк
            let likeButtonOn = cellToLike.buttons["like button on"]
            XCTAssertTrue(likeButtonOn.waitForExistence(timeout: 10), "🚨 [UI TEST ERROR]: Лайк не переключился в состояние 'like button on'")
            
            // 5. Снимаем лайк
            likeButtonOn.tap()
            
            // 6. Ждем возвращения кнопки в исходное выключенное состояние
            let likeButtonOffAgain = cellToLike.buttons["like button off"]
            XCTAssertTrue(likeButtonOffAgain.waitForExistence(timeout: 10), "🚨 [UI TEST ERROR]: Лайк не вернулся в состояние 'like button off'")
            
            sleep(2)
            
            // 7. Переходим на экран детального просмотра (SingleImage)
            cellToLike.tap()
            
            sleep(2)
            
            // 8. Ждем загрузку полноэкранной картинки
            let image = app.scrollViews.images.element(boundBy: 0)
            XCTAssertTrue(image.waitForExistence(timeout: 20), "🚨 [UI TEST ERROR]: Полноэкранная картинка не загрузилась")
            
            // 9. Тестируем зум
            image.pinch(withScale: 3, velocity: 1)
            image.pinch(withScale: 0.5, velocity: -1)
            
            // 10. Возвращаемся обратно в ленту
            let navBackButtonWhiteButton = app.buttons["nav back button white"]
            XCTAssertTrue(navBackButtonWhiteButton.waitForExistence(timeout: 5), "🚨 [UI TEST ERROR]: Кнопка возврата не найдена")
            navBackButtonWhiteButton.tap()
        }

    
    // --- ТЕСТ 3: ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ---
    func testProfile() throws {
        let profileTabButton = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(profileTabButton.waitForExistence(timeout: 10), "Таббар профиля не найден")
        profileTabButton.tap()
        
        sleep(3)
       
        let nameLabel = app.staticTexts["Name Lastname"]
        let placeholderLabel = app.staticTexts["Имя не указано"]
        XCTAssertTrue(nameLabel.exists || placeholderLabel.exists, "Профиль не загрузился")
        
        let logoutButton = app.buttons["logout button"]
        let logoutButtonAlt = app.buttons["LogOut"]
        
        if logoutButton.exists {
            logoutButton.tap()
        } else if logoutButtonAlt.exists {
            logoutButtonAlt.tap()
        }
        
        let alertEn = app.alerts["Bye bye!"]
        let alertRu = app.alerts["Пока, пока!"]
        
        if alertEn.waitForExistence(timeout: 5) {
            alertEn.buttons["Yes"].tap()
        } else if alertRu.waitForExistence(timeout: 5) {
            alertRu.buttons["Да"].tap()
        }
        
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 10), "После выхода экран авторизации не открылся")
    }
    
    // --- ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ---
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
