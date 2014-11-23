import UIKit
import HealthKit

@IBObject public class GraphViewController : UIViewController {

	public override func viewDidLoad() {
		title = "History"
		segments.tintColor = UIColor.colorWithRed(0.75, green: 0.0, blue: 0.0, alpha: 1.0)
		segments.selectedSegmentIndex = 1 // todo. persist later, for now select Month
		updateData()
	}
	
	@IBOutlet var segments: UISegmentedControl!
	@IBOutlet var chartView: GraphView!
	
	@IBAction func segmentsChanged(sender: Any?) {
		clearResults()
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
			case 2: daysNeeded = 93
				break // Silver bug
			case 3: daysNeeded = 360
				break // Silver bug
		}
		
		var mornings = NSMutableArray.arrayWithCapacity(daysNeeded)
		var evenings = NSMutableArray.arrayWithCapacity(daysNeeded)
		var lowest = NSMutableArray.arrayWithCapacity(daysNeeded)
		var lastValue: HKQuantitySample?
		var lowestValue: HKQuantitySample?
		var lastDateComps: NSDateComponents? = nil
		
		for val in values {
			
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
				if lowestValue != nil {
					lowest.addObject(lowestValue!)
					lowestValue = nil
				} else {
					// first value ever
				}
				evenings.addObject(val)
			}
			lastValue = val
			if lowestValue == nil || lowestValue!.quantity.doubleValueForUnit(MainViewController.weightUnit) > val.quantity.doubleValueForUnit(MainViewController.weightUnit) {
				lowestValue = val;
			}
		}
		
		var morningValues = NSMutableArray.arrayWithCapacity(daysNeeded)
		var eveningValues = NSMutableArray.arrayWithCapacity(daysNeeded)
		var lowestValues = NSMutableArray.arrayWithCapacity(daysNeeded)

		let minusOneDayComps = NSDateComponents()
		minusOneDayComps.day = -1
		
		var date = NSDate.date
		for var i = daysNeeded-1; i >= 0; i-- {
			
			let dateComps = NSCalendar.currentCalendar.components(NSCalendarUnit.Day | NSCalendarUnit.Month | NSCalendarUnit.Year, fromDate: date)
			date = NSCalendar.currentCalendar.dateByAddingComponents(minusOneDayComps, toDate: date, options: 0)
			
			var morning: Any = NSNull.null
			var evening: Any = NSNull.null
			var lowestVal: Any = NSNull.null
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
			for l in lowest {
				let newComps = NSCalendar.currentCalendar.components(NSCalendarUnit.Day | NSCalendarUnit.Month | NSCalendarUnit.Year, fromDate: l.endDate)
				if newComps.day == dateComps.day && newComps.month == dateComps.month && newComps.year == dateComps.year {
					lowestVal = l
					break
				}
			}
			morningValues.addObject(morning)
			eveningValues.addObject(evening)
			lowestValues.addObject(lowestVal)
		}
		
		switch segments.selectedSegmentIndex {
			case 0: daysNeeded = 7
				break // Silver bug
			case 1: daysNeeded = 31
				break // Silver bug
			case 2: daysNeeded = 93
				morningValues = limitResults(morningValues, byFactor: 3)
				eveningValues = limitResults(eveningValues, byFactor: 3)
				lowestValues = limitResults(lowestValues, byFactor: 3)
				break // Silver bug
			case 3: daysNeeded = 365
				morningValues = limitResults(morningValues, byFactor: 9)
				eveningValues = limitResults(eveningValues, byFactor: 9)
				lowestValues = limitResults(lowestValues, byFactor: 9)
				break // Silver bug
		}
		
		dispatch_async(dispatch_get_main_queue()) {
			chartView.mornings = morningValues
			chartView.evenings = eveningValues
			if segments.selectedSegmentIndex < 2 {
				chartView.lowest = lowestValues
			} else {
				chartView.lowest = nil
			}
			chartView.dataChanged()
		}
		
	}
	
	private func limitResults(_ values: NSArray, byFactor factor: Int) -> NSMutableArray { //TODO: drop _
		var result = NSMutableArray.arrayWithCapacity(values.count/factor)
		var i = 0
		while i < values.count {
			var average = 0.0
			var valueCount = 0
			for var j = 0; j < factor; j++ {
				let s = values[i]
				if s is HKQuantitySample {
					let q = s.quantity.doubleValueForUnit(MainViewController.weightUnit)
					average += q
					valueCount++
				}
				i++
			}
			if valueCount > 0 {
				let weight = HKQuantity.quantityWithUnit(MainViewController.weightUnit, doubleValue: average/valueCount)
				let dummySample = HKQuantitySample.quantitySampleWithType(MainViewController.weightQuantityType, quantity: weight, startDate: NSDate.date, endDate: NSDate.date, metadata: nil)
				result.addObject(dummySample)
			} else {
				result.addObject(NSNull.null)
			}
		}
		return result
	}
	
	private func clearResults() {
		dispatch_async(dispatch_get_main_queue()) {
			chartView.mornings = nil
			chartView.evenings = nil
			chartView.dataChanged()
		}
	}

}
