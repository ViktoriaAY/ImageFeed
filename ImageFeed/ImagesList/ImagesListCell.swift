import UIKit

final class ImagesListCell: UITableViewCell {
    
    // MARK: - Properties
    static let reuseIdentifier = "ImagesListCell"
    
    // MARK: - IBOutlets
    @IBOutlet var cellImageView: UIImageView!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var likeButton: UIButton!
}

