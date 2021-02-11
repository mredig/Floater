import UIKit

public class FloaterViewController: UIViewController {
	public override func viewDidLoad() {
		super.viewDidLoad()

		var constraints = [NSLayoutConstraint]()
		defer { NSLayoutConstraint.activate(constraints) }

		let action = UIAction { _ in
			print("pressed")
		}
		let button = UIButton(frame: .zero, primaryAction: action)
		button.setTitle("press me", for: .normal)

		button.translatesAutoresizingMaskIntoConstraints = false

		view.addSubview(button)
		constraints.append(button.centerXAnchor.constraint(equalTo: view.centerXAnchor))
		constraints.append(button.centerYAnchor.constraint(equalTo: view.centerYAnchor))
	}
}
