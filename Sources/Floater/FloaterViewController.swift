import UIKit

public class FloaterViewController: UIViewController {

	public enum SnapEdge {
		case leading
		case trailing
	}

	public let floaterContainer = UIView()

	public var inset: CGFloat = 24
	public var snapEdge = SnapEdge.trailing
	public var yPosition: CGFloat = 24

	private var dragOffset: CGSize = .zero

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

		constraints.append(contentsOf: [
			view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: floaterContainer.bottomAnchor, constant: 24),
			view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: floaterContainer.trailingAnchor, constant: 24)
		])

		// temp for testing
		floaterContainer.backgroundColor = .systemGreen

		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(floaterDragActivated))
		floaterContainer.addGestureRecognizer(longPress)
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
	}

	private func gestureMoved(_ gesture: UILongPressGestureRecognizer) {
		let location = gesture.location(in: view)
		floaterContainer.center = CGPoint(x: location.x + dragOffset.width, y: location.y + dragOffset.height)
	}

	private func gestureEnded(_ gesture: UILongPressGestureRecognizer) {
		// update to new position
	}

	private func gestureCancelled(_ gesture: UILongPressGestureRecognizer) {
		//reset to previous position
	}
}
