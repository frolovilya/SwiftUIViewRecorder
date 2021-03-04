import UIKit
import SwiftUI

extension SwiftUI.View {
    
    private var appWindow: UIWindow {
        if let window = UIApplication.shared.windows.first {
            return window
        } else {
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = UIViewController()
            window.makeKeyAndVisible()
            return window
        }
    }
    
    func placeUIView() -> UIView {
        let controller = UIHostingController(rootView: self)
        let uiView = controller.view!

        // out of screen
        uiView.frame = CGRect(x: 0, y: CGFloat(Int.max), width: 1, height: 1)
        appWindow.rootViewController?.view.addSubview(uiView)

        let size = controller.sizeThatFits(in: UIScreen.main.bounds.size)
        uiView.bounds = CGRect(origin: .zero, size: size)
        uiView.sizeToFit()
        
        return uiView
    }
    
}
