import UIKit
import AlertController

class ViewController: UIViewController {
    // A property to hold the AlertController for separate presentation
    var separateAlert: AlertController<Int>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Create buttons
        let basicAlertButton = UIButton(type: .system)
        basicAlertButton.setTitle("Show Basic Alert", for: .normal)
        basicAlertButton.addTarget(self, action: #selector(showBasicAlert), for: .touchUpInside)

        let actionSheetButton = UIButton(type: .system)
        actionSheetButton.setTitle("Show Action Sheet", for: .normal)
        actionSheetButton.addTarget(self, action: #selector(showActionSheet), for: .touchUpInside)

        let separateAlertButton = UIButton(type: .system)
        separateAlertButton.setTitle("Show Separate Presentation Alert", for: .normal)
        separateAlertButton.addTarget(self, action: #selector(showSeparateAlert), for: .touchUpInside)

        // Arrange buttons in a stack view
        let stackView = UIStackView(arrangedSubviews: [basicAlertButton, actionSheetButton, separateAlertButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)

        // Center the stack view
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // Sample 1: Basic Alert Usage
    @objc func showBasicAlert() {
        Task {
            let alert = AlertController(
                title: "Confirmation",
                message: "Do you want to proceed?",
                preferredStyle: .alert,
                dismissResult: false
            )
            alert.addAction(AlertAction(title: "Proceed", style: .default, result: true), isPreferred: true)
            alert.addAction(AlertAction(title: "Cancel", style: .cancel, result: false))

            let result = await alert.presentAndWait(on: self, animated: true)
            print("Basic Alert result: \(result)")
        }
    }

    // Sample 2: Action Sheet Usage with Popover Configuration
    @objc func showActionSheet() {
        Task {
            let sheet = AlertController(
                title: nil,
                message: "Select an option.",
                preferredStyle: .actionSheet,
                dismissResult: "Cancel"
            )
            sheet.addAction(AlertAction(title: "Option 1", style: .default, result: "Option1"))
            sheet.addAction(AlertAction(title: "Option 2", style: .default, result: "Option2"))
            sheet.addAction(AlertAction(title: "Cancel", style: .cancel, result: "Cancel"))

            // Popover configuration for iPad environment
            if let popover = sheet.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            let result = await sheet.presentAndWait(on: self, animated: true)
            print("Action Sheet result: \(result)")
        }
    }

    // Sample 3: Separated Presentation and Waiting Example
    @objc func showSeparateAlert() {
        Task {
            let alert = AlertController(
                title: "Separate Presentation",
                message: "This alert remains on screen until an action is taken or it is dismissed manually.",
                preferredStyle: .alert,
                dismissResult: 0
            )
            alert.addAction(AlertAction(title: "OK", style: .default, result: 1))
            self.separateAlert = alert

            // Separate presentation and waiting
            await alert.present(on: self, animated: true)
            let result = await alert.waitForDismissOrAction()
            print("Separate Alert result: \(result)")
            self.separateAlert = nil
        }
    }
}
