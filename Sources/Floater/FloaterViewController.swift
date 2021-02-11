import UIKit

public class FloaterViewController: UIViewController {

	public override func loadView() {
		view = PassthroughView()
	}

	public override func viewDidLoad() {
		super.viewDidLoad()

	}
}
