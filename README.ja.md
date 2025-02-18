# AlertController

**AlertController** は、Swift の非同期処理（Swift Concurrency）を活用して、`UIAlertController` の表示とユーザーからのアクション取得を簡潔に実現するライブラリです。
主な特徴は以下のとおりです。

- 非同期で結果を取得
  アラートを表示し、ユーザーの操作（ボタンタップまたはキャンセル）を待って結果を非同期で返します。

- alert と actionSheet に対応
  アラート（`UIAlertController.Style.alert`）とアクションシート（`UIAlertController.Style.actionSheet`）の両方に対応しており、iPad 環境での popover 設定も可能です。

- 柔軟な操作パターン
  - 表示と結果取得をまとめたパターン（`presentAndWait`）
  - 表示と待機処理を分離するパターン（`present` と `waitForDismissOrAction` の組み合わせ）

- 非表示にする方法
  ユーザーがボタンを押す以外にも、以下の方法でアラートを非表示にすることができます。いずれの場合も、結果として `dismissResult` が返されます。
  - `AlertController` の `dismiss()` を呼ぶ
  - 親 `ViewController` の `dismiss()` を呼ぶ

---

## **サンプル 1: 基本的な Alert の使用例**

```swift
// ViewController.swift の一部（UIKit の場合）
import UIKit
import AlertController  // ライブラリのインポート

class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task {
            let alert = AlertController(
                title: "確認",
                message: "処理を実行しますか？",
                preferredStyle: .alert,
                dismissResult: false
            )
            alert.addAction(AlertAction(title: "実行", style: .default, result: true), isPreferred: true)
            alert.addAction(AlertAction(title: "キャンセル", style: .cancel, result: false))

            let result = await alert.presentAndWait(on: self, animated: true)
            print("ユーザーの選択結果: \(result)")
        }
    }
}
```

---

## **サンプル 2: ActionSheet の使用例（popover 設定付き）**

```swift
// ViewController.swift の一部（UIKit の場合）
import UIKit
import AlertController

class ViewController: UIViewController {
    @IBAction func showActionSheet(_ sender: UIButton) {
        Task {
            let sheet = AlertController(
                title: nil,
                message: "オプションを選択してください。",
                preferredStyle: .actionSheet,
                dismissResult: "キャンセル"
            )
            sheet.addAction(AlertAction(title: "Option 1", style: .default, result: "Option1"))
            sheet.addAction(AlertAction(title: "Option 2", style: .default, result: "Option2"))
            sheet.addAction(AlertAction(title: "キャンセル", style: .cancel, result: "キャンセル"))

            if let popover = sheet.popoverPresentationController {
                popover.sourceView = sender
                popover.sourceRect = sender.bounds
            }

            let selection = await sheet.presentAndWait(on: self, animated: true)
            print("選択されたオプション: \(selection)")
        }
    }
}
```

---

## **サンプル 3: 表示と待機処理を分離した使用例**

```swift
// ViewController.swift の一部（UIKit の場合）
import UIKit
import AlertController

class ViewController: UIViewController {
    var alertController: AlertController<Int>?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Task {
            let alert = AlertController(
                title: "表示と待機を分離",
                message: "このアラートは、操作が行われるか、手動で閉じられるまで画面に表示され続けます。",
                preferredStyle: .alert,
                dismissResult: 0
            )
            alert.addAction(AlertAction(title: "OK", style: .default, result: 1))
            self.alertController = alert

            await alert.present(on: self, animated: true)

            let result = await alert.waitForDismissOrAction()
            print("結果: \(result)")
            self.alertController = nil
        }
    }
}
```
