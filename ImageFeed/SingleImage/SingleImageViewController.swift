import UIKit

final class SingleImageViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet private var singleImage: UIImageView!
    @IBOutlet private var scrollView: UIScrollView!
    
    
    // MARK: - Properties
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        configureImageScaling()
    }
    
    // MARK: - IBAction
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func didTapShareButton() {
        guard let image else { return }
        let activityViewController = UIActivityViewController (
            activityItems: [image],
            applicationActivities: nil
        )
        present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: - private func
    private func configureImageScaling() {
        guard let image else { return }
        singleImage.image = image
        singleImage.frame.size = image.size
        rescaleAndCenterImageInScrollView(image: image)
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

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return singleImage
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageInsideScrollView()
    }
}
