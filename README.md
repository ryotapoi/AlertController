# AlertController

**AlertController** is a library that leverages Swift Concurrency to simplify the display of `UIAlertController` and the asynchronous retrieval of user actions. Its main features are:

- Asynchronous Result Retrieval  
  Presents an alert and waits for the user's action (button tap or cancel) to return a result asynchronously.

- Support for Alerts and Action Sheets  
  Works with both alerts (`UIAlertController.Style.alert`) and action sheets (`UIAlertController.Style.actionSheet`), and supports configuring the popover for iPad environments.

- Flexible Operation Patterns  
  - A pattern that combines presentation and result retrieval using `presentAndWait`.
  - A pattern that separates presentation and waiting using `present` and `waitForDismissOrAction`.

- Ways to Dismiss the Alert  
  In addition to the user tapping a button, the alert can be dismissed by:
  - Calling `dismiss()` on the `AlertController`.
  - Calling `dismiss()` on the parent `ViewController`.  
  In either case, the result returned will be the `dismissResult`.

---

## **Sample 1: Basic Alert Usage**

This sample demonstrates the basic usage of `presentAndWait` to display an alert and retrieve the user's selection asynchronously.

```swift
// Part of ViewController.swift (for UIKit)
import UIKit
import AlertController  // Import the library

class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
            print("User selection: \(result)")
        }
    }
}
```

---

## **Sample 2: Action Sheet Usage with Popover Configuration**

This sample shows how to display an action sheet by specifying `.actionSheet` as the preferred style, along with configuring the `popoverPresentationController` for iPad.

```swift
// Part of ViewController.swift (for UIKit)
import UIKit
import AlertController

class ViewController: UIViewController {
    @IBAction func showActionSheet(_ sender: UIButton) {
        Task {
            let sheet = AlertController(
                title: nil,
                message: "Please select an option.",
                preferredStyle: .actionSheet,
                dismissResult: "Cancel"
            )
            sheet.addAction(AlertAction(title: "Option 1", style: .default, result: "Option1"))
            sheet.addAction(AlertAction(title: "Option 2", style: .default, result: "Option2"))
            sheet.addAction(AlertAction(title: "Cancel", style: .cancel, result: "Cancel"))
            
            if let popover = sheet.popoverPresentationController {
                popover.sourceView = sender
                popover.sourceRect = sender.bounds
            }
            
            let selection = await sheet.presentAndWait(on: self, animated: true)
            print("Selected option: \(selection)")
        }
    }
}
```

---

## **Sample 3: Separated Presentation and Waiting**

This sample demonstrates the pattern where presentation and waiting are handled separately using `present` and `waitForDismissOrAction`.

```swift
// Part of ViewController.swift (for UIKit)
import UIKit
import AlertController

class ViewController: UIViewController {
    var alertController: AlertController<Int>?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Task {
            let alert = AlertController(
                title: "Separate Presentation",
                message: "This alert remains on screen until an action is taken or it is dismissed manually.",
                preferredStyle: .alert,
                dismissResult: 0
            )
            alert.addAction(AlertAction(title: "OK", style: .default, result: 1))
            self.alertController = alert
            
            await alert.present(on: self, animated: true)
            
            let result = await alert.waitForDismissOrAction()
            print("Separate Alert result: \(result)")
            self.alertController = nil
        }
    }
}
```
