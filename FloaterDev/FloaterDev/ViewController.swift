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

		// this is just to test that touches properly get passed through
		let action = UIAction { _ in
			print("pressed background button")
		}
		let button = UIButton(frame: .zero, primaryAction: action)
		button.setTitle("press me background", for: .normal)

		button.translatesAutoresizingMaskIntoConstraints = false

		view.addSubview(button)
		constraints.append(button.centerXAnchor.constraint(equalTo: view.centerXAnchor))
		constraints.append(button.centerYAnchor.constraint(equalTo: view.centerYAnchor))

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

		view.addSubview(floaterVC.view)
		floaterVC.view.frame = view.bounds
		addChild(floaterVC)
		floaterVC.didMove(toParent: self)
	}


}

