import UIKit

public class FloaterViewController: UIViewController {

	public enum SnapEdge {
		case leading
		case trailing
	}

	public let floaterContainer = UIView()
	var floaterContainerAnchors: (leading: NSLayoutConstraint, trailing: NSLayoutConstraint, bottom: NSLayoutConstraint)?

	public var inset: CGFloat = 24
	public var snapEdge = SnapEdge.trailing
	public var yPosition: CGFloat = 24

	private var dragOffset: CGSize = .zero
	private var dragStart: CGPoint = .zero
	let proposalView = UIView()
	var proposalViewAnchors: (leading: NSLayoutConstraint, trailing: NSLayoutConstraint, bottom: NSLayoutConstraint)?

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
		constraints.forEach { $0.priority = .defaultLow }

		let floatTrailing = view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: floaterContainer.trailingAnchor, constant: inset)
		let floatLeading = floaterContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: inset)
		let floatBottom = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: floaterContainer.bottomAnchor, constant: yPosition)
		floatBottom.priority = .defaultHigh
		floaterContainerAnchors = (floatLeading, floatTrailing, floatBottom)
		constraints.append(contentsOf: [
			floatTrailing,
			floatBottom,
			floaterContainer.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor),
			view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: floaterContainer.bottomAnchor)
		])

		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(floaterDragActivated))
		floaterContainer.addGestureRecognizer(longPress)

		proposalView.backgroundColor = .systemBlue
		proposalView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(proposalView)

		let proposalTrailing = proposalView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
		let proposalLeading = proposalView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
		let proposalBottom = proposalView.bottomAnchor.constraint(equalTo: floaterContainer.bottomAnchor)
		proposalViewAnchors = (proposalLeading, proposalTrailing, proposalBottom)
		constraints.append(contentsOf: [
			proposalView.widthAnchor.constraint(equalToConstant: 8),
			proposalView.heightAnchor.constraint(equalTo: floaterContainer.heightAnchor),
			proposalTrailing,
			proposalBottom
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
		NSLayoutConstraint.deactivate([floaterAnchors.leading, floaterAnchors.trailing])
	}

	private func gestureMoved(_ gesture: UILongPressGestureRecognizer) {
		let location = gesture.location(in: view)
//		let offsetY = location.y - dragStart.y

//		floaterContainer.center = CGPoint(x: location.x + dragOffset.width, y: location.y + dragOffset.height)

		let safeFromBottom = view.safeAreaInsets.bottom
		let invertedAxis = view.frame.height - location.y
		floaterContainerAnchors?.bottom.constant = invertedAxis - safeFromBottom

		var constraints: [NSLayoutConstraint] = []
		defer { NSLayoutConstraint.activate(constraints) }

		let proposedEdge = proposedSnapEdge(for: location)
		guard
			let proposalAnchors = proposalViewAnchors,
			let containerAnchors = floaterContainerAnchors
		else { return }
		NSLayoutConstraint.deactivate([proposalAnchors.leading, proposalAnchors.trailing, containerAnchors.leading, containerAnchors.trailing])
		switch proposedEdge {
		case .leading:
			constraints.append(proposalAnchors.leading)
			constraints.append(containerAnchors.leading)
		case .trailing:
			constraints.append(proposalAnchors.trailing)
			constraints.append(containerAnchors.trailing)
		}
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
		defer { NSLayoutConstraint.activate(constraints) }

		switch snapEdge {
		case .leading:
			constraints.append(contentsOf: [floaterContainerAnchors?.leading, proposalViewAnchors?.leading].compactMap({ $0 }))
		case .trailing:
			constraints.append(contentsOf: [floaterContainerAnchors?.trailing, proposalViewAnchors?.trailing].compactMap({ $0 }))
		}

		constraints.append(contentsOf: [floaterContainerAnchors?.bottom].compactMap { $0 })
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
