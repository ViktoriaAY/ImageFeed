import XCTest

class Image_FeedUITests: XCTestCase {
    private let app = XCUIApplication()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        let app = XCUIApplication()
        // Передаем флаг очистки куки для Сплеш-контроллера
        app.launchArguments = ["clearSessionForTesting"]
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
//    func testAuth() throws {
//            // 1. Ищем и нажимаем кнопку "Authenticate" на стартовом экране
//            let authButton = app.buttons["Authenticate"]
//            XCTAssertTrue(authButton.waitForExistence(timeout: 10), "🚨 [UI TEST ERROR]: Кнопка 'Authenticate' не найдена")
//            authButton.tap()
//            
//            // 2. Ждем появление WebView
//            let webView = app.webViews["UnsplashWebView"]
//            XCTAssertTrue(webView.waitForExistence(timeout: 15), "🚨 [UI TEST ERROR]: WebView не появился")
//            
//            // 3. Безопасно ищем поля ввода БЕЗ использования жестких XCTAssertTrue
//            let emailField = webView.descendants(matching: .textField).element(boundBy: 0)
//            let passwordField = webView.descendants(matching: .secureTextField).element(boundBy: 0)
//            
//            // Даем сайту 5 секунд зафиксироваться
//            _ = emailField.waitForExistence(timeout: 5)
//            
//            // Если поля ввода физически присутствуют на экране — заполняем их
//            if emailField.exists && passwordField.exists {
//                emailField.tap()
//                emailField.typeText("v.perxun@inbox.ru") // Укажите вашу почту
//                
//                passwordField.tap()
//                passwordField.typeText("kawxeq-sehsog-0tiqMy") // Укажите ваш пароль
//                
//                // Нажимаем встроенную кнопку входа на веб-странице
//                let loginButton = webView.buttons["Login"]
//                if loginButton.waitForExistence(timeout: 5) {
//                    loginButton.tap()
//                }
//            }
//            
//            // 4. Логика для случая, если мы уже авторизованы или заполнили поля выше:
//            // Ждем появление кнопки одобрения прав ("Allow" / "Authorize" / "Join" или первая кнопка на сайте)
//            let allowButton = webView.buttons["Allow"]
//            let authorizeButton = webView.buttons["Authorize"]
//            let generalWebButton = webView.descendants(matching: .button).element(boundBy: 0)
//            
//            if allowButton.waitForExistence(timeout: 10) {
//                allowButton.tap()
//            } else if authorizeButton.exists {
//                authorizeButton.tap()
//            } else if generalWebButton.exists {
//                // Если текст кнопки изменился, просто кликаем по первой кнопке веб-интерфейса
//                generalWebButton.tap()
//            }
//            
//            // 5. Финальная проверка: после клика по "Allow" мы обязаны попасть в основную ленту приложения
//            let tablesQuery = app.tables
//            let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
//            XCTAssertTrue(cell.waitForExistence(timeout: 25), "🚨 [UI TEST ERROR]: Авторизация не удалась, ячейка ленты не появилась на экране за 25 секунд")
//        }
    func testAuth() throws {
        print("🤖 [UI TEST] Начало теста testAuth")
        
        // 1. ПРОВЕРКА НА УЖЕ ОТКРЫТУЮ ЛЕНТУ
        let imagesListTable = app.tables["ImagesListTable"]
        if imagesListTable.waitForExistence(timeout: 5) && imagesListTable.children(matching: .cell).element(boundBy: 0).exists {
            print("🎉 [UI TEST] Приложение уже авторизовано, лента на экране! Завершаем тест успехом.")
            return
        }
        
        // 2. СТАНДАРТНЫЙ СЦЕНАРИЙ АВТОРИЗАЦИИ
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 5), "Кнопка 'Authenticate' не найдена")
        print("🤖 [UI TEST] Кликаем по кнопке Authenticate")
        authButton.tap()
        
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 15), "WebView не загрузился")
        print("🤖 [UI TEST] WebView UnsplashWebView успешно обнаружен на экране")
        
        // --- СТАБИЛЬНОЕ ОЖИДАНИЕ ЗАГРУЗКИ HTML-СТРАНИЦЫ ---
        print("🤖 [UI TEST] Ожидаем отрисовку элементов внутри WebView...")
        let emailField = webView.descendants(matching: .textField).element(boundBy: 0)
        
        if !emailField.waitForExistence(timeout: 30) {
            XCTFail("Поля ввода не появились в WebView")
            return
        }
        
        let passwordField = webView.descendants(matching: .secureTextField).element(boundBy: 0)
        XCTAssertTrue(passwordField.exists, "Поле пароля не найдено")
        
        // 3. НАДЕЖНЫЙ ВВОД ЛОГИНА
        print("🤖 [UI TEST] Вводим логин...")
        emailField.tap()
        emailField.typeText("v.perxun@inbox.ru")
        closeKeyboard()
        
        print("🤖 [UI TEST] Скроллим к паролю...")
        webView.swipeUp()
        
        // 4. НАДЕЖНЫЙ ВВОД ПАРОЛЯ ЧЕРЕЗ БУФЕР ОБМЕНА (Защита от Invalid password)
        print("🤖 [UI TEST] Копируем и вставляем пароль...")
        passwordField.tap()
        
        // Копируем текст пароля в системный буфер обмена симулятора
        UIPasteboard.general.string = "kawxeq-sehsog-0tiqMy"
        
        // Делаем двойной тап по полю, чтобы вызвать меню UIKit, и нажимаем «Вставить»
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
        webView.tap() // убираем фокус с полей
        
        // Ищем кнопку входа
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
        
        // --- ПРОВЕРКА ЭКРАНА ДОСТУПА (ALLOW ACCESS) ---
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

    // --- ТЕСТ 2: ЛЕНТА (FEED) ---
    func testFeed() throws {
        let tablesQuery = app.tables
        
        // 1. Ждем загрузку первой ячейки в ленте
        let cellToLike = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cellToLike.waitForExistence(timeout: 20), "🚨 [UI TEST ERROR]: Первая ячейка ленты не загрузилась")
        
        sleep(3) // Даем Kingfisher время убрать скелетон
        
        // 2. Находим кнопку лайка на первой ячейке
        let likeButtonOff = tablesQuery.children(matching: .cell).element(boundBy: 0).buttons["like button off"]
        XCTAssertTrue(likeButtonOff.waitForExistence(timeout: 10), "🚨 [UI TEST ERROR]: Кнопка 'like button off' не найдена")
        
        // 3. Ставим лайк
        likeButtonOff.forceTap()
        
        // 4. Ждем, пока состояние изменится на включенный лайк
        let likeButtonOn = tablesQuery.children(matching: .cell).element(boundBy: 0).buttons["like button on"]
        XCTAssertTrue(likeButtonOn.waitForExistence(timeout: 10), "🚨 [UI TEST ERROR]: Лайк не переключился в состояние 'like button on'")
        
        // 5. Снимаем лайк
        likeButtonOn.forceTap()
        
        // 6. Ждем возвращения кнопки в исходное выключенное состояние
        let likeButtonOffAgain = tablesQuery.children(matching: .cell).element(boundBy: 0).buttons["like button off"]
        XCTAssertTrue(likeButtonOffAgain.waitForExistence(timeout: 10), "🚨 [UI TEST ERROR]: Лайк не вернулся в состояние 'like button off'")
        
        sleep(2)
        
        // 7. Переходим на экран детального просмотра (SingleImage)
        let finalCell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        finalCell.tap()
        
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
            // 1. Находим и нажимаем на вкладку Профиля в Таббаре
            let profileTabButton = app.tabBars.buttons.element(boundBy: 1)
            XCTAssertTrue(profileTabButton.waitForExistence(timeout: 10), "🚨 [UI TEST ERROR]: Таббар профиля не найден")
            profileTabButton.tap()
            
            sleep(3) // Даем время профилю загрузить данные из сети
            
            // 2. Стабильная проверка: ищем текстовую метку по ее идентификатору, а не по тексту!
            let profileNameLabel = app.staticTexts["Name Label"]
            XCTAssertTrue(profileNameLabel.waitForExistence(timeout: 5), "🚨 [UI TEST ERROR]: Экран профиля не загрузился или не найден Name Label")
            
            // 3. Находим кнопку логаута по идентификатору
            let logoutButton = app.buttons["logout button"]
            XCTAssertTrue(logoutButton.waitForExistence(timeout: 5), "🚨 [UI TEST ERROR]: Кнопка выхода 'logout button' не найдена")
            logoutButton.tap()
            
            // 4. Обрабатываем системное диалоговое окно (Алерт подтверждения выхода)
            let alertEn = app.alerts["Bye bye!"]
            let alertRu = app.alerts["Пока, пока!"]
            
            if alertEn.waitForExistence(timeout: 5) {
                alertEn.buttons["Yes"].tap()
            } else if alertRu.waitForExistence(timeout: 5) {
                alertRu.buttons["Да"].tap()
            } else {
                // Если алерт имеет другой заголовок, нажимаем первую попавшуюся кнопку согласия
                app.alerts.element.buttons.element(boundBy: 0).tap()
            }
            
            // 5. Проверяем, что после логаута мы успешно вернулись на стартовый экран входа
            let authButton = app.buttons["Authenticate"]
            XCTAssertTrue(authButton.waitForExistence(timeout: 10), "🚨 [UI TEST ERROR]: После выхода экран авторизации не открылся")
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

extension XCUIElement {
    func forceTap() {
        let coordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
    }
}
