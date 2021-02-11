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



		view.addSubview(floaterVC.view)
		floaterVC.view.frame = view.bounds
		addChild(floaterVC)
		floaterVC.didMove(toParent: self)
	}


}

