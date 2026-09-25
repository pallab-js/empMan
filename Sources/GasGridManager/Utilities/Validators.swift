import Foundation

enum Validators {
    static func isValidEmail(_ email: String) -> Bool {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    /// Returns a user-facing error message, or nil when the email is acceptable.
    static func emailValidationError(_ email: String, existing: [Employee], excluding id: UUID? = nil) -> String? {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if email.isEmpty { return nil }
        guard isValidEmail(email) else { return "Enter a valid email address" }
        if existing.contains(where: { $0.id != id && $0.email.caseInsensitiveCompare(email) == .orderedSame }) {
            return "This email is already in use"
        }
        return nil
    }
}
