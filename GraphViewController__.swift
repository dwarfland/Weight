import UIKit
import HealthKit

@IBObject public class GraphViewController : UIViewController {

	public override func viewDidLoad() {
		title = "Chart"
		segments.tintColor = UIColor.colorWithRed(0.75, green: 0.0, blue: 0.0, alpha: 1.0)
		segments.selectedSegmentIndex = 1 // todo. persist later, for now select Month

		if navigationItem.rightBarButtonItem == nil {
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Numbers", style: .Plain, target: self, action: "showNumbers:")
		}

		updateData()
	}
	
	@IBAction func showNumbers(sendr: Any?) {
		performSegueWithIdentifier("ShowNumbers", sender: nil)
	}

	@IBOutlet var segments: UISegmentedControl!
	@IBOutlet var chartView: GraphView!
	
	@IBAction func segmentsChanged(sender: Any?) {
		clearResults()
		updateData()
	}
	
	private func updateData() { 

		var daysNeeded = 0
		switch segments.selectedSegmentIndex {
			default:
			case 0: daysNeeded = 7
			case 1: daysNeeded = 31
			case 2: daysNeeded = 93
			case 3: daysNeeded = 360
		}

		DataAccess.sharedInstance.getData(days: daysNeeded, callback: { (data: CollectedWeightData?) in 

			if let actualData = data {
				//data.limitDataForSelection( segments.selectedSegmentIndex) // 70911: Silver: misleading error about "assembly" visibility on nullable
				actualData.limitDataForSelection( segments.selectedSegmentIndex)
				
				dispatch_async(dispatch_get_main_queue()) {
					chartView.mornings = actualData.morningValues
					chartView.evenings = actualData.eveningValues
					if segments.selectedSegmentIndex < 2 {
						chartView.lowest = actualData.lowestValues
					} else {
						chartView.lowest = nil
					}
					chartView.dataChanged()
				}
			} else {
				clearResults()
			}
			
		})
		
	}
	
	private func gotData(data: CollectedWeightData!) {
		NSLog("in callback")
		NSLog("data address: %ld", data)
		NSLog("data: %@", data)
		

		if let actualData = data {
			
			actualData.limitDataForSelection( segments.selectedSegmentIndex)
			dispatch_async(dispatch_get_main_queue()) {
				chartView.mornings = actualData.morningValues
				chartView.evenings = actualData.eveningValues
				if segments.selectedSegmentIndex < 2 {
					chartView.lowest = actualData.lowestValues
				} else {
					chartView.lowest = nil
				}
				chartView.dataChanged()
			}
		}

		/*if let actualData = data {
			NSLog("data: %@", data)
		}*/
		/*if let actualData = data {
			NSLog("data: %@", data)
			//data.limitDataForSelection( segments.selectedSegmentIndex) // 70911: Silver: misleading error about "assembly" visibility on nullable
			NSLog("1")
			actualData.limitDataForSelection( segments.selectedSegmentIndex)
			//NSLog("2")
			
			dispatch_async(dispatch_get_main_queue()) {
				chartView.mornings = actualData.morningValues
				chartView.evenings = actualData.eveningValues
				if segments.selectedSegmentIndex < 2 {
					chartView.lowest = actualData.lowestValues
				} else {
					chartView.lowest = nil
				}
				chartView.dataChanged()
			}
			//NSLog("3")
		} else {
			clearResults()
		}*/
	}
	
	private func clearResults() {
		dispatch_async(dispatch_get_main_queue()) {
			chartView.mornings = nil
			chartView.evenings = nil
			chartView.lowest = nil
			chartView.dataChanged()
		}
	}

}
