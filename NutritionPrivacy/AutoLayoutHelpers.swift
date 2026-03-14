import UIKit

/// Constraint-first helpers for Auto Layout in UIKit.
///
/// All helpers create explicit constraints, activate them immediately, and return those
/// constraints for callers that need to store references for updates.
public extension UIView {
    /// Pins this view to another anchor source.
    ///
    /// - Parameters:
    ///   - anchorSource: A `UIView` or `UILayoutGuide` providing layout anchors.
    ///   - edges: Which edges to constrain.
    ///   - insets: Positive values inset the child from each edge.
    /// - Returns: The activated edge constraints.
    @discardableResult
    func pinEdges(
        to anchorSource: AutoLayoutAnchorSource,
        edges: AutoLayoutEdges = .all,
        insets: UIEdgeInsets = .zero
    ) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint] = []
        if edges.contains(.top) {
            constraints.append(topAnchor.constraint(equalTo: anchorSource.topAnchor, constant: insets.top))
        }
        if edges.contains(.leading) {
            constraints.append(leadingAnchor.constraint(equalTo: anchorSource.leadingAnchor, constant: insets.left))
        }
        if edges.contains(.bottom) {
            constraints.append(bottomAnchor.constraint(equalTo: anchorSource.bottomAnchor, constant: -insets.bottom))
        }
        if edges.contains(.trailing) {
            constraints.append(trailingAnchor.constraint(equalTo: anchorSource.trailingAnchor, constant: -insets.right))
        }

        constraints.forEach { $0.isActive = true }
        return constraints
    }

    /// Pins this view to a view's safe-area layout guide.
    ///
    /// - Parameters:
    ///   - view: View whose safe area is used.
    ///   - edges: Which edges to constrain.
    ///   - insets: Positive values inset the child from each edge.
    /// - Returns: The activated edge constraints.
    @discardableResult
    func pinEdgesToSafeArea(
        _ view: UIView,
        edges: AutoLayoutEdges = .all,
        insets: UIEdgeInsets = .zero
    ) -> [NSLayoutConstraint] {
        return pinEdges(to: view.safeAreaLayoutGuide, edges: edges, insets: insets)
    }

    /// Aligns this view to another anchor source.
    ///
    /// - Parameters:
    ///   - anchorSource: A `UIView` or `UILayoutGuide` providing layout anchors.
    ///   - alignments: Which alignment anchors to match.
    ///   - offset: Offset applied to center and horizontal/vertical alignments.
    /// - Returns: The activated alignment constraints.
    @discardableResult
    func align(
        to anchorSource: AutoLayoutAnchorSource,
        _ alignments: AutoLayoutAlignments,
        offset: CGPoint = .zero
    ) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint] = []
        if alignments.contains(.leading) {
            constraints.append(leadingAnchor.constraint(equalTo: anchorSource.leadingAnchor, constant: offset.x))
        }
        if alignments.contains(.trailing) {
            constraints.append(trailingAnchor.constraint(equalTo: anchorSource.trailingAnchor, constant: offset.x))
        }
        if alignments.contains(.top) {
            constraints.append(topAnchor.constraint(equalTo: anchorSource.topAnchor, constant: offset.y))
        }
        if alignments.contains(.bottom) {
            constraints.append(bottomAnchor.constraint(equalTo: anchorSource.bottomAnchor, constant: offset.y))
        }
        if alignments.contains(.centerX) {
            constraints.append(centerXAnchor.constraint(equalTo: anchorSource.centerXAnchor, constant: offset.x))
        }
        if alignments.contains(.centerY) {
            constraints.append(centerYAnchor.constraint(equalTo: anchorSource.centerYAnchor, constant: offset.y))
        }

        constraints.forEach { $0.isActive = true }
        return constraints
    }

    /// Aligns this view to a view's safe-area layout guide.
    ///
    /// - Parameters:
    ///   - view: View whose safe area is used.
    ///   - alignments: Which alignment anchors to match.
    ///   - offset: Offset applied to center and horizontal/vertical alignments.
    /// - Returns: The activated alignment constraints.
    @discardableResult
    func alignToSafeArea(
        _ view: UIView,
        _ alignments: AutoLayoutAlignments,
        offset: CGPoint = .zero
    ) -> [NSLayoutConstraint] {
        return align(to: view.safeAreaLayoutGuide, alignments, offset: offset)
    }

    /// Centers this view in a non-layout-guide anchor source.
    ///
    /// - Parameters:
    ///   - anchorSource: A `UIView` or `UILayoutGuide`.
    ///   - offset: Offset from exact center.
    /// - Returns: Active `centerX` and `centerY` constraints.
    @discardableResult
    func center(
        in anchorSource: AutoLayoutAnchorSource,
        offset: CGPoint = .zero
    ) -> [NSLayoutConstraint] {
        return align(to: anchorSource, .centerXAndCenterY, offset: offset)
    }

    /// Sets fixed size constraints.
    ///
    /// - Parameters:
    ///   - width: Optional fixed width in points.
    ///   - height: Optional fixed height in points.
    /// - Returns: Active size constraints.
    @discardableResult
    func setSize(width: CGFloat? = nil, height: CGFloat? = nil) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        if let width {
            let constraint = widthAnchor.constraint(equalToConstant: width)
            constraint.isActive = true
            constraints.append(constraint)
        }
        if let height {
            let constraint = heightAnchor.constraint(equalToConstant: height)
            constraint.isActive = true
            constraints.append(constraint)
        }
        return constraints
    }

    /// Matches this view's size with another anchor source.
    ///
    /// - Parameters:
    ///   - anchorSource: A `UIView` or `UILayoutGuide` providing width/height anchors.
    ///   - multiplier: Size factor.
    ///   - widthOffset: Constant added to width equation.
    ///   - heightOffset: Constant added to height equation.
    /// - Returns: Active width and height constraints.
    @discardableResult
    func matchSize(
        to anchorSource: AutoLayoutAnchorSource,
        multiplier: CGFloat = 1,
        widthOffset: CGFloat = 0,
        heightOffset: CGFloat = 0
    ) -> [NSLayoutConstraint] {
        let widthConstraint = widthAnchor.constraint(
            equalTo: anchorSource.widthAnchor,
            multiplier: multiplier,
            constant: widthOffset
        )
        let heightConstraint = heightAnchor.constraint(
            equalTo: anchorSource.heightAnchor,
            multiplier: multiplier,
            constant: heightOffset
        )
        widthConstraint.isActive = true
        heightConstraint.isActive = true
        return [widthConstraint, heightConstraint]
    }

    /// Matches this view's width to another anchor source.
    ///
    /// - Parameters:
    ///   - anchorSource: A `UIView` or `UILayoutGuide` providing width anchors.
    ///   - multiplier: Width factor.
    ///   - constant: Constant added to width equation.
    /// - Returns: Active width constraint.
    @discardableResult
    func matchWidth(
        to anchorSource: AutoLayoutAnchorSource,
        multiplier: CGFloat = 1,
        constant: CGFloat = 0
    ) -> NSLayoutConstraint {
        let constraint = widthAnchor.constraint(equalTo: anchorSource.widthAnchor, multiplier: multiplier, constant: constant)
        constraint.isActive = true
        return constraint
    }

    /// Matches this view's height to another anchor source.
    ///
    /// - Parameters:
    ///   - anchorSource: A `UIView` or `UILayoutGuide` providing height anchors.
    ///   - multiplier: Height factor.
    ///   - constant: Constant added to height equation.
    /// - Returns: Active height constraint.
    @discardableResult
    func matchHeight(
        to anchorSource: AutoLayoutAnchorSource,
        multiplier: CGFloat = 1,
        constant: CGFloat = 0
    ) -> NSLayoutConstraint {
        let constraint = heightAnchor.constraint(equalTo: anchorSource.heightAnchor, multiplier: multiplier, constant: constant)
        constraint.isActive = true
        return constraint
    }
}

/// Shared anchor surface for `UIView` and `UILayoutGuide`.
public protocol AutoLayoutAnchorSource {
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
}

extension UIView: AutoLayoutAnchorSource {}
extension UILayoutGuide: AutoLayoutAnchorSource {}

/// Reusable edge options for `pinEdges(...)`.
public struct AutoLayoutEdges: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let top = AutoLayoutEdges(rawValue: 1 << 0)
    public static let leading = AutoLayoutEdges(rawValue: 1 << 1)
    public static let bottom = AutoLayoutEdges(rawValue: 1 << 2)
    public static let trailing = AutoLayoutEdges(rawValue: 1 << 3)

    public static let all: AutoLayoutEdges = [.top, .leading, .bottom, .trailing]
}

/// Reusable alignment options for `align(...)`.
public struct AutoLayoutAlignments: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let leading = AutoLayoutAlignments(rawValue: 1 << 0)
    public static let trailing = AutoLayoutAlignments(rawValue: 1 << 1)
    public static let top = AutoLayoutAlignments(rawValue: 1 << 2)
    public static let bottom = AutoLayoutAlignments(rawValue: 1 << 3)
    public static let centerX = AutoLayoutAlignments(rawValue: 1 << 4)
    public static let centerY = AutoLayoutAlignments(rawValue: 1 << 5)

    public static let centerXAndCenterY: AutoLayoutAlignments = [.centerX, .centerY]
    public static let all: AutoLayoutAlignments = [.leading, .trailing, .top, .bottom, .centerX, .centerY]
}
