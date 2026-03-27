import UIKit
import Dependencies

@MainActor
final class MainViewController: UIViewController {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(didTapSettings)
        )
    }
    
    
    @available(iOS 26.0, *)
    override func updateProperties() {
        super.updateProperties()
        _updateProperties()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #unavailable(iOS 26) {
            _updateProperties()
        }
    }
    
    private func _updateProperties() {
        if appState.isSetup {

        } else {

        }
    }

    @objc
    private func didTapSettings() {
    }
}
