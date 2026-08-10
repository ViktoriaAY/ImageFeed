import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var singleImage: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    // MARK: - Properties
    var image: UIImage?
    var imageURL: URL?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        loadFullImage()
    }
    
    // MARK: - IBAction
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func didTapShareButton() {
        guard let image = singleImage.image else { return }
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: - Private Methods
    
    private func loadFullImage() {
        guard let imageURL = imageURL else { return }
        UIBlockingProgressHUD.show()
        
        singleImage.kf.setImage(with: imageURL) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            
            guard let self = self else { return }
            
            switch result {
            case .success(let imageResult):
                self.image = imageResult.image
                self.singleImage.frame.size = imageResult.image.size
                self.rescaleAndCenterImageInScrollView(image: imageResult.image)
            case .failure:
                self.showErrorAlert()
            }
        }
    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так.",
            message: "Попробуйте ещё раз",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Не надо", style: .cancel))
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.loadFullImage()
        })
        present(alert, animated: true)
    }
    
    private func setupScrollView() {
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        scrollView.delegate = self
    }
    
    private func centerImageInsideScrollView() {
        view.layoutIfNeeded()
        let visibleRectSize = scrollView.bounds.size
        let newContentSize = scrollView.contentSize
        let xOffset = max(0, (newContentSize.width - visibleRectSize.width) / 2)
        let yOffset = max(0, (newContentSize.height - visibleRectSize.height) / 2)
        scrollView.setContentOffset(CGPoint(x: xOffset, y: yOffset), animated: false)
        let xInset = max(0, (visibleRectSize.width - newContentSize.width) / 2)
        let yInset = max(0, (visibleRectSize.height - newContentSize.height) / 2)
        scrollView.contentInset = UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let scale = min(maxZoomScale, max(minZoomScale, max(hScale, vScale)))
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        centerImageInsideScrollView()
    }
}

// MARK: - UIScrollViewDelegate

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return singleImage
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageInsideScrollView()
    }
}
