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

		view.addSubview(floaterVC.view)
		floaterVC.view.frame = view.bounds
		addChild(floaterVC)
		floaterVC.didMove(toParent: self)

	}


}

