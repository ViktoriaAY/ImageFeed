import XCTest
@testable import ImageFeed

// MARK: - ProfileViewControllerSpy

final class ProfileViewControllerSpy: ProfileViewControllerProtocol {
    var updateProfileDetailsCalled = false
    var updateAvatarCalled = false
    var startSkeletonAnimationCalled = false
    var removeGradientAnimationCalled = false
    var switchToSplashViewControllerCalled = false
    
    var passedName: String?
    var passedNickname: String?
    var passedBio: String?
    var passedURL: URL?
    
    func updateProfileDetails(name: String, nickname: String, bio: String) {
        updateProfileDetailsCalled = true
        passedName = name
        passedNickname = nickname
        passedBio = bio
    }
    
    func updateAvatar(with url: URL) {
        updateAvatarCalled = true
        passedURL = url
    }
    
    func startSkeletonAnimation() {
        startSkeletonAnimationCalled = true
    }
    
    func removeGradientAnimation() {
        removeGradientAnimationCalled = true
    }
    
    func switchToSplashViewController() {
        switchToSplashViewControllerCalled = true
    }
}

// MARK: - ProfilePresenterSpy

final class ProfilePresenterSpy: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    var viewDidLoadCalled = false
    var didTapLogoutButtonCalled = false
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func didTapLogoutButton() {
        didTapLogoutButtonCalled = true
    }
}

// MARK: - Mocks for Services

final class ProfileServiceMock: ProfileServiceProtocol {
    var profile: Profile?
}

final class ProfileImageServiceMock: ProfileImageServiceProtocol {
    var avatarURL: String?
}

final class ProfileLogoutServiceSpy: ProfileLogoutServiceProtocol {
    var logoutCalled = false
    func logout() {
        logoutCalled = true
    }
}

// MARK: - ProfileViewTests

final class ProfileViewTests: XCTestCase {
    
    @MainActor func testViewControllerCallsViewDidLoad() {
        // Given
        let viewController = ProfileViewController()
        let presenterSpy = ProfilePresenterSpy()
        
        viewController.presenter = presenterSpy
        presenterSpy.view = viewController
        
        // When
        _ = viewController.view
        
        // Then
        XCTAssertTrue(presenterSpy.viewDidLoadCalled)
    }
    
    func testPresenterCallsSwitchToSplashOnLogout() {
        // Given
        let viewSpy = ProfileViewControllerSpy()
        let logoutServiceSpy = ProfileLogoutServiceSpy()
        let presenter = ProfilePresenter(
            profileService: ProfileServiceMock(),
            profileImageService: ProfileImageServiceMock(),
            profileLogoutService: logoutServiceSpy
        )
        presenter.view = viewSpy
        
        // When
        presenter.didTapLogoutButton()
        
        // Then
        XCTAssertTrue(logoutServiceSpy.logoutCalled)
        XCTAssertTrue(viewSpy.switchToSplashViewControllerCalled)
    }
    
    func testPresenterSetsPlaceholdersWhenFieldsAreEmpty() {
        // Given
        let viewSpy = ProfileViewControllerSpy()
        let profileServiceMock = ProfileServiceMock()
        
        // Создаем пустой профиль
        profileServiceMock.profile = Profile(username: "", name: "", loginName: "", bio: "")
        
        let presenter = ProfilePresenter(
            profileService: profileServiceMock,
            profileImageService: ProfileImageServiceMock(),
            profileLogoutService: ProfileLogoutServiceSpy()
        )
        presenter.view = viewSpy
        
        // When
        presenter.viewDidLoad()
        
        // Then
        XCTAssertEqual(viewSpy.passedName, ConstantProfileView.ProfileView.namePlaceholder)
        XCTAssertEqual(viewSpy.passedNickname, ConstantProfileView.ProfileView.nicknamePlaceholder)
        XCTAssertEqual(viewSpy.passedBio, ConstantProfileView.ProfileView.descriptionPlaceholder)
    }
}
