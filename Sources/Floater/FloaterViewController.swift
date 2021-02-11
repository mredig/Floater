import UIKit

public class FloaterViewController: UIViewController {

	public enum SnapEdge {
		case leading
		case trailing
	}

	public struct AnchorVariants {
		let leading: NSLayoutConstraint
		let leadingHidden: NSLayoutConstraint?
		let trailing: NSLayoutConstraint
		let trailingHidden: NSLayoutConstraint?
		let whenMoving: NSLayoutConstraint?
		let bottom: NSLayoutConstraint

		init(
			leadingVisible: NSLayoutConstraint,
			leadingHidden: NSLayoutConstraint? = nil,
			trailingVisible: NSLayoutConstraint,
			trailingHidden: NSLayoutConstraint? = nil,
			whenMoving: NSLayoutConstraint? = nil,
			bottom: NSLayoutConstraint) {

			self.leading = leadingVisible
			self.leadingHidden = leadingHidden
			self.trailing = trailingVisible
			self.trailingHidden = trailingHidden
			self.whenMoving = whenMoving
			self.bottom = bottom

			self.bottom.priority = .defaultLow - 1
		}

		var all: [NSLayoutConstraint] {
			[leading, leadingHidden, trailing, trailingHidden, whenMoving, bottom].compactMap { $0 }
		}

		var allToggled: [NSLayoutConstraint] {
			[leadingHidden, leading, trailingHidden, whenMoving, trailing].compactMap { $0 }
		}

		func active(for snapEdge: SnapEdge, visible: Bool) -> [NSLayoutConstraint] {
			var constraints: [NSLayoutConstraint?] = [bottom]
			let other: NSLayoutConstraint?
			switch snapEdge {
			case .leading:
				other = visible ? leading : leadingHidden
			case .trailing:
				other = visible ? trailing : trailingHidden
			}
			constraints.append(other)
			return constraints.compactMap { $0 }
		}
	}

	public let floaterContainer = UIView()
	var floaterContainerAnchors: AnchorVariants?

	public var inset: CGFloat = 24
	public var snapEdge = SnapEdge.trailing
	// from bottom safe area
	public var yPosition: CGFloat = 24

	public var isShowing = true {
		didSet {
			updateVisibility()
		}
	}

	public var animationSpeed: TimeInterval = 0.5

	private var dragOffset: CGSize = .zero
	let proposalView = UIView()
	var proposalViewAnchors: AnchorVariants?

	public override func loadView() {
		view = PassthroughView()
	}

	public override func viewDidLoad() {
		super.viewDidLoad()

		view.addSubview(floaterContainer)
		floaterContainer.translatesAutoresizingMaskIntoConstraints = false

		var constraints: [NSLayoutConstraint] = []
		defer { NSLayoutConstraint.activate(constraints) }

		constraints.append(contentsOf: [
			floaterContainer.widthAnchor.constraint(equalToConstant: 55),
			floaterContainer.heightAnchor.constraint(equalToConstant: 55)
		])
		constraints.forEach { $0.priority = .defaultLow - 1 }

		let floaterContainerAnchors = AnchorVariants(
			leadingVisible: floaterContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: inset),
			leadingHidden: view.leadingAnchor.constraint(equalTo: floaterContainer.trailingAnchor),
			trailingVisible: view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: floaterContainer.trailingAnchor, constant: inset),
			trailingHidden: floaterContainer.leadingAnchor.constraint(equalTo: view.trailingAnchor),
			whenMoving: floaterContainer.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
			bottom: view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: floaterContainer.bottomAnchor, constant: yPosition))
		self.floaterContainerAnchors = floaterContainerAnchors
		constraints.append(contentsOf: [
			floaterContainer.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor),
			view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: floaterContainer.bottomAnchor)
		])

		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(floaterDragActivated))
		floaterContainer.addGestureRecognizer(longPress)

		proposalView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
		proposalView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(proposalView)

		let proposalWidth: CGFloat = 6

		let proposalViewAnchors = AnchorVariants(
			leadingVisible: proposalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			trailingVisible: proposalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			bottom: proposalView.bottomAnchor.constraint(equalTo: floaterContainer.bottomAnchor))
		self.proposalViewAnchors = proposalViewAnchors
		constraints.append(contentsOf: [
			proposalView.widthAnchor.constraint(equalToConstant: proposalWidth),
			proposalView.heightAnchor.constraint(equalTo: floaterContainer.heightAnchor),
		])

		proposalView.layer.cornerRadius = proposalWidth / 2

		proposalView.isHidden = true
		applySettings(animate: false)
	}

	@objc private func floaterDragActivated(_ gesture: UILongPressGestureRecognizer) {
		switch gesture.state {
		case .began:
			gestureBegan(gesture)
		case .changed:
			gestureMoved(gesture)
		case .ended:
			gestureEnded(gesture)
		case .cancelled, .failed:
			gestureCancelled(gesture)
		default:
			break
		}
	}

	private func gestureBegan(_ gesture: UILongPressGestureRecognizer) {
		let location = gesture.location(in: view)
		dragOffset = .init(width: floaterContainer.center.x - location.x, height: floaterContainer.center.y - location.y)
		proposalView.isHidden = false

		guard let floaterAnchors = floaterContainerAnchors else { return }
		NSLayoutConstraint.deactivate(floaterAnchors.allToggled)
	}

	private func gestureMoved(_ gesture: UILongPressGestureRecognizer) {
		let location = gesture.location(in: view)

		floaterContainerAnchors?.bottom.constant = bottomConstant(for: location)
		floaterContainerAnchors?.whenMoving?.constant = location.x + dragOffset.width

		var constraints: [NSLayoutConstraint] = []
		defer { NSLayoutConstraint.activate(constraints) }

		let proposedEdge = proposedSnapEdge(for: location)
		guard
			let proposalViewAnchors = proposalViewAnchors,
			let floaterContainerAnchors = floaterContainerAnchors
		else { return }
		NSLayoutConstraint.deactivate(proposalViewAnchors.allToggled + floaterContainerAnchors.allToggled)
		constraints.append(contentsOf: proposalViewAnchors.active(for: proposedEdge, visible: isShowing))

		floaterContainerAnchors.whenMoving?.isActive = true
	}

	private func gestureEnded(_ gesture: UILongPressGestureRecognizer) {
		// update to new position
		let location = gesture.location(in: view)
		snapEdge = proposedSnapEdge(for: location)
		yPosition = bottomConstant(for: location)

		applySettings()
	}

	private func gestureCancelled(_ gesture: UILongPressGestureRecognizer) {
		//reset to previous position
		applySettings()
	}

	private func applySettings(animate: Bool = true) {
		var constraints: [NSLayoutConstraint] = []
		defer {
			let block = { [self] in
				floaterContainerAnchors?.whenMoving?.isActive = false
				floaterContainerAnchors?.leading.constant = inset
				floaterContainerAnchors?.trailing.constant = inset
				floaterContainerAnchors?.bottom.constant = yPosition

				NSLayoutConstraint.activate(constraints)
				view.layoutIfNeeded()
			}

			if animate {
				UIView.animate(
					withDuration: animationSpeed,
					delay: 0,
					usingSpringWithDamping: 0.7,
					initialSpringVelocity: 0,
					options: [],
					animations: block,
					completion: { success in })
			} else {
				block()
			}
		}

		constraints += floaterContainerAnchors?.active(for: snapEdge, visible: isShowing) ?? []
		constraints += proposalViewAnchors?.active(for: snapEdge, visible: isShowing) ?? []

		proposalView.isHidden = true
	}

	private func proposedSnapEdge(for location: CGPoint) -> SnapEdge {
		let leftThreshold = view.bounds.size.width / 2

		if location.x < leftThreshold {
			return .leading
		} else {
			return .trailing
		}
	}

	private func bottomConstant(for location: CGPoint) -> CGFloat {
		let safeFromBottom = view.safeAreaInsets.bottom
		let invertedAxis = view.frame.height - location.y
		return invertedAxis - safeFromBottom - dragOffset.height - (floaterContainer.bounds.height / 2)
	}

	private func updateVisibility() {
		NSLayoutConstraint.deactivate(floaterContainerAnchors?.allToggled ?? [])
		NSLayoutConstraint.activate(floaterContainerAnchors?.active(for: snapEdge, visible: isShowing) ?? [])
		view.layoutIfNeeded()
	}
}
