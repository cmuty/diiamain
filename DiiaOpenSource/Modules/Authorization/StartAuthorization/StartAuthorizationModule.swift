import UIKit
import DiiaMVPModule
       
final class StartAuthorizationModule: BaseModule {
    private let view: StartAuthorizationViewController
    private let presenter: StartAuthorizationPresenter
    
    init() {
        view = StartAuthorizationViewController.storyboardInstantiate()
        presenter = StartAuthorizationPresenter(view: view)
        view.presenter = presenter
    }

    func viewController() -> UIViewController {
        return view
    }
}
