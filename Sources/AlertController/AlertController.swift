import UIKit

/// Represents an alert action.
///
/// - note: T can be any Sendable type.
public struct AlertAction<T: Sendable> {
    /// The text displayed on the button.
    public let title: String
    /// The button style (UIAlertAction.Style).
    public let style: UIAlertAction.Style
    /// The value returned when the action is selected.
    public let result: T

    /// Initializes an AlertAction with a title, style, and result.
    ///
    /// - Parameters:
    ///   - title: The text to display on the button.
    ///   - style: The style of the button.
    ///   - result: The result associated with the action.
    public init(title: String, style: UIAlertAction.Style, result: T) {
        self.title = title
        self.style = style
        self.result = result
    }
}

/// Displays an alert and asynchronously retrieves the user's response.
public class AlertController<T: Sendable>: NSObject, UIAdaptivePresentationControllerDelegate {

    // MARK: - Internal Implementation

    /// A subclass of UIAlertController that executes a handler upon deinitialization.
    private class DismissAwareAlertController: UIAlertController {
        /// A handler that is executed upon deinitialization.
        var onDismissHandler: (@Sendable () -> Void)?

        deinit {
            onDismissHandler?()
        }

        /// Sets the dismiss handler.
        ///
        /// - Parameter handler: A closure executed when the alert is dismissed.
        func setOnDismissHandler(_ handler: @escaping @Sendable () -> Void) {
            self.onDismissHandler = handler
        }
    }

    // MARK: - Private Properties

    /// Stores the latest result.
    private var pendingResult: T?

    /// A strong reference to the alert controller during setup.
    private var retainedAlertController: DismissAwareAlertController?

    /// A weak reference to the alert controller when presented.
    private weak var presentedAlertController: DismissAwareAlertController?

    /// Returns the current alert controller.
    private var activeAlertController: DismissAwareAlertController? {
        retainedAlertController ?? presentedAlertController
    }

    /// A CheckedContinuation used to resume an asynchronous await call.
    private var continuation: CheckedContinuation<T, Never>?

    /// The result returned when no action is selected.
    private var dismissResult: T

    // MARK: - Public Properties

    /// Accesses the popover presentation settings of the UIAlertController.
    public var popoverPresentationController: UIPopoverPresentationController? {
        return activeAlertController?.popoverPresentationController
    }

    // MARK: - Initializer

    /// Initializes an AlertController with specified parameters.
    ///
    /// - Parameters:
    ///   - title: The alert's title.
    ///   - message: The alert's message.
    ///   - preferredStyle: The style of the alert (e.g., .alert, .actionSheet).
    ///   - dismissResult: The result returned when no action is selected.
    public init(
        title: String?, message: String?, preferredStyle: UIAlertController.Style, dismissResult: T
    ) {
        self.retainedAlertController = DismissAwareAlertController(
            title: title, message: message, preferredStyle: preferredStyle
        )
        self.presentedAlertController = self.retainedAlertController
        self.dismissResult = dismissResult
        super.init()

        // Set a dismissal handler that resumes the continuation with the default dismissResult.
        // This ensures that if the alert is dismissed without any action, the waiting task receives a result.
        self.retainedAlertController?.setOnDismissHandler { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.resume(returning: self.dismissResult)
            }
        }
    }

    // MARK: - Public Methods

    /// Adds an action to the alert.
    ///
    /// - Parameters:
    ///   - action: The action to add.
    ///   - isPreferred: True if this action is preferred.
    public func addAction(_ action: AlertAction<T>, isPreferred: Bool = false) {
        let uiAction = UIAlertAction(title: action.title, style: action.style) { [weak self] _ in
            self?.resume(returning: action.result)
        }
        activeAlertController?.addAction(uiAction)
        if isPreferred {
            activeAlertController?.preferredAction = uiAction
        }
    }

    /// Adds multiple actions to the alert.
    ///
    /// - Parameter actions: An array of actions to add.
    public func addActions(_ actions: [AlertAction<T>]) {
        for action in actions {
            addAction(action)
        }
    }

    /// Presents the alert on the specified view controller and awaits the result.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to display the alert.
    ///   - animated: True to animate the presentation.
    /// - Returns: The user's action result, or dismissResult.
    @MainActor
    public func presentAndWait(on viewController: UIViewController, animated: Bool) async -> T {
        await withTaskCancellationHandler { [weak self] in
            await withCheckedContinuation { continuation in
                guard let self = self else {
                    fatalError("AlertController was deallocated during presentation.")
                }
                guard let retainedAlertController = self.retainedAlertController else {
                    #if DEBUG
                        fatalError("retainedAlertController is nil.")
                    #else
                        continuation.resume(returning: self.dismissResult)
                        return
                    #endif
                }

                self.continuation = continuation
                viewController.present(retainedAlertController, animated: animated)
                // Release the strong reference after presentation.
                self.retainedAlertController = nil
            }
        } onCancel: { [weak self] in
            // Do not resume here; onDismissHandler will handle resuming the continuation.
            Task { @MainActor in
                self?.activeAlertController?.dismiss(animated: animated, completion: nil)
            }
        }
    }

    /// Presents the alert on the specified view controller.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to display the alert.
    ///   - animated: True to animate the presentation.
    @MainActor
    public func present(on viewController: UIViewController, animated: Bool) async {
        await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                fatalError("AlertController was deallocated during presentation.")
            }
            guard let retainedAlertController = self.retainedAlertController else {
                #if DEBUG
                    fatalError("retainedAlertController is nil.")
                #else
                    continuation.resume()
                    return
                #endif
            }

            viewController.present(retainedAlertController, animated: animated) {
                continuation.resume()
            }
            self.retainedAlertController = nil
        }
    }

    /// Awaits the user's action or alert dismissal.
    ///
    /// - Returns: The result of the user's action, or dismissResult.
    @MainActor
    public func waitForDismissOrAction() async -> T {
        if let result = pendingResult {
            return result
        }

        return await withTaskCancellationHandler { [weak self] in
            await withCheckedContinuation { continuation in
                guard let self = self else {
                    fatalError("AlertController was deallocated while waiting.")
                }
                self.continuation = continuation
            }
        } onCancel: { [weak self] in
            // Do not resume here; onDismissHandler will handle resuming the continuation.
            Task { @MainActor in
                self?.activeAlertController?.dismiss(animated: true, completion: nil)
            }
        }
    }

    /// Dismisses the alert.
    ///
    /// - Parameter flag: True to dismiss with animation.
    @MainActor
    public func dismiss(animated flag: Bool) async {
        await withCheckedContinuation { continuation in
            activeAlertController?.dismiss(animated: flag) {
                continuation.resume()
            }
        }
    }

    // MARK: - Private Methods

    /// Resumes the suspended asynchronous operation with the given result.
    ///
    /// - Parameter returning: The result to be returned to the awaiting task.
    private func resume(returning: T) {
        pendingResult = returning

        if let continuation = continuation {
            continuation.resume(returning: returning)
            self.continuation = nil
        }
    }
}
