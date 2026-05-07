import UIKit

extension UIFont {
    static func roundedSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let baseFont = UIFont.systemFont(ofSize: size, weight: weight)

        guard
            let roundedDescriptor = baseFont.fontDescriptor.withDesign(.rounded)
        else {
            return baseFont
        }

        return UIFont(descriptor: roundedDescriptor, size: size)
    }
}
