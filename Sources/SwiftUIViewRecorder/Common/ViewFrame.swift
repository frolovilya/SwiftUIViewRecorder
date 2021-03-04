import UIKit

/// Represents either `UIImage` already rendered view frame or `UIView` view snapshot for delayed rendering
struct ViewFrame {
    private let image: UIImage?
    private let snapshot: UIView?
    
    init(image: UIImage) {
        self.image = image
        self.snapshot = nil
    }
    
    init(snapshot: UIView) {
        self.image = nil
        self.snapshot = snapshot
    }
    
    func render() -> UIImage {
        if image != nil {
            return image!
        } else {
            return snapshot!.asImage(afterScreenUpdates: true)
        }
    }
}
