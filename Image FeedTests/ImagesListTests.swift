import XCTest
@testable import ImageFeed

final class ImagesListViewPresenterSpy: ImagesListViewPresenterProtocol {
    weak var view: ImagesListViewControllerProtocol?
    var photos: [Photo] = []
    var viewDidLoadCalled = false
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func fetchPhotosNextPageIfNeeded(by indexPath: IndexPath) {}
    func calculateCellHeight(for indexPath: IndexPath, tableViewWidth: CGFloat) -> CGFloat { return 0 }
    func changeLike(at indexPath: IndexPath, completion: @escaping (Result<Void, Error>) -> Void) {}
}

final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    var presenter: ImagesListViewPresenterProtocol?
    var updateTableViewAnimatedCalled = false
    
    func updateTableViewAnimated(oldCount: Int, newCount: Int) {
        updateTableViewAnimatedCalled = true
    }
    
    func setCellLiked(at indexPath: IndexPath, isLiked: Bool) {}
    func showLikeErrorAlert() {}
}

final class ImagesListTests: XCTestCase {
    
    func testViewControllerCallsViewDidLoad() {
        // Given
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as! ImagesListViewController
        let presenterSpy = ImagesListViewPresenterSpy()
        viewController.configure(presenterSpy)
        
        // When
        _ = viewController.view
        
        // Then
        XCTAssertTrue(presenterSpy.viewDidLoadCalled)
    }
    
    func testPresenterTriggersViewUpdateOnNotification() {
        // Given
        let presenter = ImagesListPresenter()
        let viewControllerSpy = ImagesListViewControllerSpy()
        presenter.view = viewControllerSpy
        viewControllerSpy.presenter = presenter
        
        // When
        presenter.viewDidLoad()
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)
        
        // Then
        XCTAssertTrue(viewControllerSpy.updateTableViewAnimatedCalled)
    }
}

