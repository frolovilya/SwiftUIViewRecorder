import SwiftUI
import Combine

/// `View` image capturing `ViewModel`
public class ViewImageCapturingViewModel: ObservableObject {
    
    /// Generated `View` image representation
    @Published public var image: UIImage?
    private var imageCancellable: AnyCancellable?
    
    public init() {}
        
    /**
     Capture `View` as `UIImage`.
     
     Result will be published in the `image` view model's property.
     */
    public func captureImage<V: SwiftUI.View>(view: V) {
        imageCancellable = view.asImage().sink { uiImage in
            self.image = uiImage
        }
    }
    
}
