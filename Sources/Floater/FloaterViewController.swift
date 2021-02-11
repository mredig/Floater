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
	public var yPosition: CGFloat = 24

	public var isShowing = true

	private var dragOffset: CGSize = .zero
	private var dragStart: CGPoint = .zero
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
			trailingHidden: floaterContainer.trailingAnchor.constraint(equalTo: view.leadingAnchor),
			whenMoving: floaterContainer.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
			bottom: view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: floaterContainer.bottomAnchor, constant: yPosition))
		self.floaterContainerAnchors = floaterContainerAnchors
		constraints.append(contentsOf: [
			floaterContainerAnchors.trailing,
			floaterContainerAnchors.bottom,
			floaterContainer.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor),
			view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: floaterContainer.bottomAnchor)
		])

		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(floaterDragActivated))
		floaterContainer.addGestureRecognizer(longPress)

		proposalView.backgroundColor = .systemBlue
		proposalView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(proposalView)

		let proposalViewAnchors = AnchorVariants(
			leadingVisible: proposalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			trailingVisible: proposalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			bottom: proposalView.bottomAnchor.constraint(equalTo: floaterContainer.bottomAnchor))
		self.proposalViewAnchors = proposalViewAnchors
		constraints.append(contentsOf: [
			proposalView.widthAnchor.constraint(equalToConstant: 8),
			proposalView.heightAnchor.constraint(equalTo: floaterContainer.heightAnchor),
			proposalViewAnchors.trailing,
			proposalViewAnchors.bottom
		])

		proposalView.isHidden = true

		// temp for testing
		floaterContainer.backgroundColor = .systemGreen
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
		dragStart = location
		proposalView.isHidden = false

		guard let floaterAnchors = floaterContainerAnchors else { return }
		NSLayoutConstraint.deactivate(floaterAnchors.allToggled)
	}

	private func gestureMoved(_ gesture: UILongPressGestureRecognizer) {
		let location = gesture.location(in: view)

		let safeFromBottom = view.safeAreaInsets.bottom
		let invertedAxis = view.frame.height - location.y
		floaterContainerAnchors?.bottom.constant = invertedAxis - safeFromBottom
		floaterContainerAnchors?.whenMoving?.constant = location.x

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
		snapEdge = proposedSnapEdge(for: gesture.location(in: view))
		applySettings()
	}

	private func gestureCancelled(_ gesture: UILongPressGestureRecognizer) {
		//reset to previous position
		applySettings()
	}

	private func applySettings() {
		var constraints: [NSLayoutConstraint] = []
		defer {
			UIView.animate(
				withDuration: 0.5,
				delay: 0,
				usingSpringWithDamping: 0.7,
				initialSpringVelocity: 0,
				options: [],
				animations: { [self] in
					floaterContainerAnchors?.whenMoving?.isActive = false
					floaterContainerAnchors?.leading.constant = inset
					floaterContainerAnchors?.trailing.constant = inset

					NSLayoutConstraint.activate(constraints)
					view.layoutSubviews()
				},
				completion: { success in })
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
}
