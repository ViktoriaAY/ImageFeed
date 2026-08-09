import UIKit

extension UIView {
    
    func addSkeletonAnimation(cornerRadius: CGFloat = 0) {
        
        if layer.sublayers?.contains(where: { $0.name == "SkeletonGradient" }) == true { return }
        
        let gradient = CAGradientLayer()
        gradient.name = "SkeletonGradient"
        gradient.frame = CGRect(origin: .zero, size: bounds.size)
        gradient.locations = [0, 0.1, 0.3]
        gradient.colors = [
            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor,
            UIColor(red: 0.531, green: 0.533, blue: 0.553, alpha: 1).cgColor,
            UIColor(red: 0.431, green: 0.433, blue: 0.453, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = cornerRadius
        gradient.masksToBounds = true
        
        
        let gradientChangeAnimation = CABasicAnimation(keyPath: "locations")
        gradientChangeAnimation.duration = 1.0
        gradientChangeAnimation.repeatCount = .infinity
        gradientChangeAnimation.fromValue = [0, 0.1, 0.3]
        gradientChangeAnimation.toValue = [0, 0.8, 1]
        
        gradient.add(gradientChangeAnimation, forKey: "locationsChange")
        layer.addSublayer(gradient)
    }
    
    func removeSkeletonAnimation() {
        layer.sublayers?.removeAll(where: { $0.name == "SkeletonGradient" })
    }
}

