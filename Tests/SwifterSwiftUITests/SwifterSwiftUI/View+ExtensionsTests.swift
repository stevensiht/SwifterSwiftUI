import XCTest
import SwiftUI
import ViewInspector
@testable import SwifterSwiftUI

final class ViewExtensionsTests: XCTestCase {
    // MARK: General
    func testEraseToAnyView() {
        let anyView = EmptyView().eraseToAnyView()
        XCTAssertNoThrow(try anyView.inspect().anyView().emptyView())
    }

    // MARK: Building
    func testIfThen() {
        let withZIndex = EmptyView().if(true, then: { $0.zIndex(13) })
        withZIndex.inspect { (view) in
            XCTAssertNoThrow(try view.anyView().emptyView().zIndex())
        }

        let withoutZIndex = EmptyView().if(false, then: { $0.zIndex(13) })
        withoutZIndex.inspect { (view) in
            XCTAssertThrowsError(try view.anyView().emptyView().zIndex())
        }
    }

    func testIfThenElse() {
        let firstIndex = 9.0, secondIndex = 13.0
        let firstView = EmptyView().if(true, then: { $0.zIndex(firstIndex) }, else: { $0.zIndex(secondIndex)})
        firstView.inspect { (view) in
            XCTAssertEqual(try view.anyView().emptyView().zIndex(), firstIndex)
        }

        let secondView = EmptyView().if(false, then: { $0.zIndex(firstIndex) }, else: { $0.zIndex(secondIndex)})
        secondView.inspect { (view) in
            XCTAssertEqual(try view.anyView().emptyView().zIndex(), secondIndex)
        }
    }

    func testConditionalModifier() {
        let testView = Text("Text")

        // Test true condition
        var modifier = InspectableTestModifier()
        let firstExp = XCTestExpectation()
        modifier.onAppear = { body in
            ViewHosting.expel()
            firstExp.fulfill()
        }
        let view = testView.conditionalModifier(true, modifier)
        ViewHosting.host(view: view)
        wait(for: [firstExp], timeout: 0.1)

        // Test false condition
        var secondModifier = InspectableTestModifier()
        let secondExp = XCTestExpectation()
        secondExp.isInverted = true
        secondModifier.onAppear = { body in
            ViewHosting.expel()
            secondExp.fulfill()
        }
        let secondView = testView.conditionalModifier(false, secondModifier)
        ViewHosting.host(view: secondView)
        wait(for: [secondExp], timeout: 0.1)
    }

    func testConditionalModifierOr() {
        let testView = Text("Text")

        // Test true condition
        var thenModifier = InspectableTestModifier()
        let firstExp = XCTestExpectation()
        thenModifier.onAppear = { body in
            ViewHosting.expel()
            firstExp.fulfill()
        }
        var elseModifier = InspectableTestModifier()
        let firstView = testView.conditionalModifier(true, thenModifier, elseModifier)
        ViewHosting.host(view: firstView)
        wait(for: [firstExp], timeout: 0.1)

        // Test false condition
        let secondExp = XCTestExpectation()
        thenModifier.onAppear = nil
        elseModifier.onAppear = { body in
            ViewHosting.expel()
            secondExp.fulfill()
        }
        let secondView = testView.conditionalModifier(false, thenModifier, elseModifier)
        ViewHosting.host(view: secondView)
        wait(for: [secondExp], timeout: 0.1)
    }

    static var allTests = [
        ("testEraseToAnyView", testEraseToAnyView),
        ("testIfThen", testIfThen),
        ("testIfThenElse", testIfThenElse)
    ]
}

private struct TestModifier: ViewModifier {
    func body(content: Self.Content) -> some View {
        content.onAppear()
    }
}

private struct InspectableTestModifier: ViewModifier {
    var onAppear: ((Self.Body) -> Void)?

    func body(content: Self.Content) -> some View {
        content
            .padding(.top, 15)
            .onAppear { self.onAppear?(self.body(content: content)) }
    }
}
