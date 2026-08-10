import UIKit
import ProgressHUD

final class UIBlockingProgressHUD {
    private static var window: UIWindow? {
        return UIApplication.shared.windows.first
    }
    
    @MainActor static func show() {
        window?.isUserInteractionEnabled = false
        ProgressHUD.animate()
    }

    @MainActor static func dismiss() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
    } 
}
