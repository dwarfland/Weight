import UIKit
import HealthKit

@IBObject public class GraphViewController : UIViewController {

	public override func viewDidLoad() {
		segments.tintColor = UIColor.colorWithRed(0.75, green: 0.0, blue: 0.0, alpha: 1.0)
		updateData()
	}
	
	@IBOutlet var segments: UISegmentedControl!
	@IBOutlet var chartView: GraphView!
	
	@IBAction func segmentsChanged(sender: Any?) {
		updateData()
	}
	
	private func updateData() { 

		let descriptor = NSSortDescriptor.sortDescriptorWithKey(HKSampleSortIdentifierEndDate, ascending: false)
		let q = HKSampleQuery(sampleType: MainViewController.weightQuantityType, 
							  predicate: nil, 
							  limit: 1000, 
							  sortDescriptors: [descriptor],
							  resultsHandler: { (explicit: HKSampleQuery!, results: NSArray?, error: NSError?) in 
							  
			if let e = error {
				NSLog("error: %@", error)
			} else {
				if results?.count > 0 {
					processResults(results!)
				} else {
					clearResults()
				}
			}
		})   
				
		MainViewController.healthStore.executeQuery(q)	
	}
	
	private func processResults(values: NSArray) {
		
		var daysNeeded = 0
		switch segments.selectedSegmentIndex {
			case 0: daysNeeded = 7
				break // Silver bug
			case 1: daysNeeded = 31
				break // Silver bug
			case 2: daysNeeded = 365
				break // Silver bug
		}
		
		var mornings = NSMutableArray.arrayWithCapacity(daysNeeded)
		var evenings = NSMutableArray.arrayWithCapacity(daysNeeded)
		var lastValue: HKSample?
		var lastDateComps: NSDateComponents? = nil
		
		for val in values {
		   //NSLog("value: %@", val)
			
			var sameDay = false
			let newComps = NSCalendar.currentCalendar.components(NSCalendarUnit.Day | NSCalendarUnit.Month | NSCalendarUnit.Year, fromDate: val.endDate)
			if let oldComps = lastDateComps {
				sameDay = newComps.day == oldComps.day && newComps.month == oldComps.month && newComps.year == oldComps.year
			}
			lastDateComps = newComps
			
			if !sameDay{
				if lastValue != nil {
					mornings.addObject(lastValue!)
				} else {
					// first value ever
				}
				evenings.addObject(val)
			}
			lastValue = val
		}
		
		var morningValues = NSMutableArray.arrayWithCapacity(daysNeeded)
		var eveningValues = NSMutableArray.arrayWithCapacity(daysNeeded)

		let minusOneDayComps = NSDateComponents()
		minusOneDayComps.day = -1;
		
		var date = NSDate.date
		for var i = daysNeeded-1; i >= 0; i-- {
			
			let dateComps = NSCalendar.currentCalendar.components(NSCalendarUnit.Day | NSCalendarUnit.Month | NSCalendarUnit.Year, fromDate: date)
			date = NSCalendar.currentCalendar.dateByAddingComponents(minusOneDayComps, toDate: date, options: 0)
			
			var morning: Any = NSNull.null
			var evening: Any = NSNull.null
			for m in mornings {
				let newComps = NSCalendar.currentCalendar.components(NSCalendarUnit.Day | NSCalendarUnit.Month | NSCalendarUnit.Year, fromDate: m.endDate)
				if newComps.day == dateComps.day && newComps.month == dateComps.month && newComps.year == dateComps.year {
					morning = m
					break
				}
			}
			for e in evenings {
				let newComps = NSCalendar.currentCalendar.components(NSCalendarUnit.Day | NSCalendarUnit.Month | NSCalendarUnit.Year, fromDate: e.endDate)
				if newComps.day == dateComps.day && newComps.month == dateComps.month && newComps.year == dateComps.year {
					evening = e
					break
				}
			}
			morningValues.addObject(morning)
			eveningValues.addObject(evening)
		}
		
		NSLog("mornings = %@", morningValues)
		NSLog("evenings = %@", eveningValues)
		
		dispatch_async(dispatch_get_main_queue()) {
			chartView.mornings = morningValues;
			chartView.evenings = eveningValues;
			chartView.dataChanged()
		}
		
	}
	
	private func clearResults() {
	}

}
