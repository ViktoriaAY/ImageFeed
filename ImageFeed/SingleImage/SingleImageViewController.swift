import UIKit

final class SingleImageViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet var SingleImage: UIImageView!
    
    // MARK: - Properties
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SingleImage.image = image
    }
}
