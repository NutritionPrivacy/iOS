# NutritionPrivacy Agent Guide

This project is a UIKit iOS app. Follow these conventions when adding or modifying code.

## Architecture

- Use the `Observable` macro for view models.
- Keep view models small and focused on UI-facing state.
- Put business logic in dependency clients, not in view models or view controllers.
- Use `swift-dependencies` for dependency management.
- Model dependencies as `struct`s by default.
- Prefer `DependenciesMacros` automatic generation by annotating dependency structs with `@DependencyClient`.

## UIKit Structure

- This is a UIKit project, not a SwiftUI project.
- Use routers for navigation and screen wiring.
- Each router is responsible for exactly one `UIViewController`.
- Keep each view controller narrowly scoped to rendering, user interaction, and delegating work outward.

## View Model And Dependency Boundaries

- A view model may transform dependency outputs into presentation state.
- A view model should not contain core business rules, persistence logic, networking logic, or orchestration that belongs in a dependency client.
- If logic is reusable across screens or non-trivial enough to test independently, move it into a dependency client.

## Rendering And Observation

When using observable state from UIKit, keep rendering in a single method so iOS 18 fallback code and iOS 26+ tracked updates cannot drift.

Preferred pattern:

```swift
private func applyModelToView() {
    textLabel.text = model.message
    counterLabel.text = "\(model.counter)"
}

@available(iOS 26.0, *)
override func updateProperties() {
    super.updateProperties()

    // Reading model properties here sets up observation tracking.
    applyModelToView()
}

override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    if #available(iOS 26.0, *) { return }
    applyModelToView()
}
```

Rules for this pattern:

- Do not duplicate UI assignments between `updateProperties()` and pre-iOS-26 fallback code.
- Put all state-to-view assignments in one shared render method such as `applyModelToView()`.
- `updateProperties()` should call only that shared render method after `super.updateProperties()`.
- The fallback path for iOS 18 should call the same shared render method.

## Defaults

- Prefer simple, composable types over inheritance-heavy designs.
- Keep files small and responsibilities explicit.
- Favor testable dependency boundaries over ad hoc singleton access.
