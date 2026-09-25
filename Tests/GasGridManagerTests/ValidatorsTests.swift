import XCTest
@testable import GasGridManager

final class ValidatorsTests: XCTestCase {
    func testValidEmails() {
        XCTAssertTrue(Validators.isValidEmail("john.doe@example.com"))
        XCTAssertTrue(Validators.isValidEmail("jane+tag@sub.domain.co"))
        XCTAssertTrue(Validators.isValidEmail("a_b%c@corp.example.org"))
    }

    func testInvalidEmails() {
        XCTAssertFalse(Validators.isValidEmail(""))
        XCTAssertFalse(Validators.isValidEmail("   "))
        XCTAssertFalse(Validators.isValidEmail("not-an-email"))
        XCTAssertFalse(Validators.isValidEmail("missing@tld"))
        XCTAssertFalse(Validators.isValidEmail("double@@example.com"))
        XCTAssertFalse(Validators.isValidEmail("trailing.dot@example."))
        XCTAssertFalse(Validators.isValidEmail("spaces in@example.com"))
    }

    func testTrimsSurroundingWhitespaceBeforeMatching() {
        XCTAssertTrue(Validators.isValidEmail("  john@example.com  "))
        XCTAssertFalse(Validators.isValidEmail("  not-an-email  "))
    }

    func testDuplicateEmailIsRejectedCaseInsensitively() {
        let id = UUID()
        let existing = [Employee(id: id, firstName: "John", lastName: "Smith", email: "john@example.com")]

        XCTAssertNotNil(Validators.emailValidationError("JOHN@example.com", existing: existing))
        XCTAssertNotNil(Validators.emailValidationError("  john@example.com ", existing: existing))
        XCTAssertNil(Validators.emailValidationError("other@example.com", existing: existing))
        XCTAssertNil(Validators.emailValidationError("", existing: existing))
    }

    func testEmployeeMayKeepTheirOwnEmailWhenEditing() {
        let id = UUID()
        let existing = [Employee(id: id, firstName: "John", lastName: "Smith", email: "john@example.com")]

        XCTAssertNil(Validators.emailValidationError("john@example.com", existing: existing, excluding: id))
        XCTAssertNotNil(Validators.emailValidationError("john@example.com", existing: existing, excluding: UUID()))
    }
}
