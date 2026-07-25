import Foundation

/// Where a failure came from. Only Dove's own faults are worth a support report -
/// a wrong API key or a denied permission is something the user can fix.
enum ErrorOrigin {
    /// Dove misbehaved: a subsystem failed, stalled, or was missing.
    case internalFault
    /// Expected outcome from the provider, the system, or the user's setup.
    case expected
}

/// Single funnel for failures: log the technical detail for debugging, hand back a
/// friendly message for the UI. Callers never format error text themselves.
enum ErrorReporter {
    /// Logs `error` under `context` and returns the message to show the user.
    @discardableResult
    static func report(
        _ error: Error,
        context: String,
        origin: ErrorOrigin = .internalFault
    ) -> String {
        let message = HUDErrorMessage.from(error)
        record(context: context, detail: String(describing: error), origin: origin)
        return message
    }

    /// Logs a failure that has no `Error` value behind it.
    @discardableResult
    static func report(
        _ context: String,
        reason: String,
        message: String = HUDErrorMessage.generic,
        origin: ErrorOrigin = .internalFault
    ) -> String {
        record(context: context, detail: reason, origin: origin)
        return message
    }

    /// Task cancellation is a normal outcome, not something to show the user.
    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return false
    }

    private static func record(context: String, detail: String, origin: ErrorOrigin) {
        print("[Dove] \(context) failed: \(detail)")
        guard origin == .internalFault else { return }
        DiagnosticLog.recordFailure(context: context, detail: detail)
    }
}
