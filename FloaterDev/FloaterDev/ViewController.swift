//
//  ViewController.swift
//  FloaterDev
//
//  Created by Michael Redig on 2/11/21.
//

import UIKit
import Floater

class ViewController: UIViewController {

	let floaterVC = FloaterViewController()

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .systemPink

		var constraints = [NSLayoutConstraint]()
		defer { NSLayoutConstraint.activate(constraints) }

		let toggleAction = UIAction { [weak self] _ in
			UIView.animate(
				withDuration: 0.5,
				delay: 0,
				usingSpringWithDamping: 0.65,
				initialSpringVelocity: 0,
				options: [],
				animations: {
					self?.floaterVC.isShowing.toggle()
				},
				completion: nil)
		}

		let toggleButton = UIButton(frame: .zero, primaryAction: toggleAction)
		toggleButton.setTitle("Toggle Visibility", for: .normal)
		toggleButton.translatesAutoresizingMaskIntoConstraints = false

		view.addSubview(toggleButton)
		constraints.append(toggleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor))
		constraints.append(toggleButton.centerYAnchor.constraint(equalTo: view.centerYAnchor))

		let testAction = UIAction { _ in
			print("pressed testing")
		}

		let systemAction = UIAction { _ in
			print("pressed system")
		}


		let testButton = UIButton()
		testButton.setTitle("Testing!", for: .normal)
		testButton.addAction(testAction, for: .touchUpInside)

		let testButton2 = UIButton(type: .system)
		testButton2.setTitle("System", for: .normal)
		testButton2.addAction(systemAction, for: .touchUpInside)

		let stackView = UIStackView()
		stackView.addArrangedSubview(testButton)
		stackView.addArrangedSubview(testButton2)
		stackView.spacing = 8
		floaterVC.floaterContainer.addSubview(stackView)
		stackView.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			stackView.leadingAnchor.constraint(equalTo: floaterVC.floaterContainer.leadingAnchor),
			stackView.trailingAnchor.constraint(equalTo: floaterVC.floaterContainer.trailingAnchor),
			stackView.topAnchor.constraint(equalTo: floaterVC.floaterContainer.topAnchor),
			stackView.bottomAnchor.constraint(equalTo: floaterVC.floaterContainer.bottomAnchor),
		])

		stackView.backgroundColor = .systemGray
		stackView.layer.cornerRadius = 8

		// configure here
		floaterVC.animationSpeed = 0.5
		floaterVC.yPosition = 24
		floaterVC.inset = 24
		floaterVC.snapEdge = .trailing

		view.addSubview(floaterVC.view)
		floaterVC.view.frame = view.bounds
		addChild(floaterVC)
		floaterVC.didMove(toParent: self)
	}
}

