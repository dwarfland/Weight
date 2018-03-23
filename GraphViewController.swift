import UIKit
import HealthKit

@IBObject public class GraphViewController : UIViewController {

	public override func viewDidLoad() {
		title = "Chart"
		segments.tintColor = UIColor.colorWithRed(0.75, green: 0.0, blue: 0.0, alpha: 1.0)

		if let index = UserDefaults.standardUserDefaults.objectForKey(KEY_SELECTED_CHART_SEGMENT) {
			segments.selectedSegmentIndex = index.integerValue
		} else {
			segments.selectedSegmentIndex = 1
		}

		if navigationItem.rightBarButtonItem == nil {
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Numbers", style: .Plain, target: self, action: #selector(showNumbers:))
		}

		updateData()
	}

	@IBAction func showNumbers(_ sender: Any?) {
		performSegueWithIdentifier("ShowNumbers", sender: nil)
	}

	@IBOutlet var segments: UISegmentedControl!
	@IBOutlet var chartView: GraphView!

	@IBAction func segmentsChanged(_ sender: Any?) {
		clearResults()
		UserDefaults.standardUserDefaults.setInteger(segments.selectedSegmentIndex, forKey: KEY_SELECTED_CHART_SEGMENT)
		updateData()
	}

	static let KEY_SELECTED_CHART_SEGMENT = "SelectedChartSegment"

	private func updateData() {

		let date = NSDate.date;

		let descriptor = NSSortDescriptor.sortDescriptorWithKey(HKSampleSortIdentifierEndDate, ascending: false)
		let q = HKSampleQuery(sampleType: DataAccess.weightQuantityType,
							  predicate: nil,
							  limit: 10000,
							  sortDescriptors: [descriptor],
							  resultsHandler: { (explicit: HKSampleQuery!, results: NSArray?, error: NSError?) in

			NSLog("-- updateData took %f, %ld records", -date.timeIntervalSinceNow, results != nil ? results!.count : -1);

			if let e = error {
				NSLog("error: %@", error)
			} else {
				if results?.count > 0 {
					self.processResults(results!)
				} else {
					self.clearResults()
				}
			}
		})

		DataAccess.healthStore.executeQuery(q)
	}

	private func processResults(_ values: NSArray) {

		var daysNeeded = 0
		switch segments.selectedSegmentIndex {
			case 0: daysNeeded = 7
			case 1: daysNeeded = 31
			case 2: daysNeeded = 93
			case 3: daysNeeded = 360
			case 4: daysNeeded = 756*3
			default: return
		}

		var mornings = NSMutableArray.arrayWithCapacity(daysNeeded)
		var evenings = NSMutableArray.arrayWithCapacity(daysNeeded)
		var lowest = NSMutableArray.arrayWithCapacity(daysNeeded)
		var lastValue: HKQuantitySample? = nil
		var lowestValue: HKQuantitySample? = nil
		var lastDateComps: NSDateComponents? = nil

		for val in values {

			var sameDay = false
			let newComps = NSCalendar.currentCalendar.components(NSCalendarUnit.DayCalendarUnit | NSCalendarUnit.MonthCalendarUnit | NSCalendarUnit.YearCalendarUnit, fromDate: val.endDate)
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
				var low2 = lowestValue
				if low2 != nil {
					lowest.addObject(low2)
					lowestValue = nil
				} else {
					// first value ever
				}
				evenings.addObject(val)
			}
			lastValue = val
			if lowestValue == nil || lowestValue!.quantity.doubleValueForUnit(DataAccess.weightUnit) > val.quantity.doubleValueForUnit(DataAccess.weightUnit) {
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

			let dateComps = NSCalendar.currentCalendar.components(NSCalendarUnit.DayCalendarUnit | NSCalendarUnit.MonthCalendarUnit | NSCalendarUnit.YearCalendarUnit, fromDate: date)
			date = NSCalendar.currentCalendar.dateByAddingComponents(minusOneDayComps, toDate: date, options: 0)

			var morning: Any = NSNull.null
			var evening: Any = NSNull.null
			var lowestVal: Any = NSNull.null
			for m in mornings {
				let newComps = NSCalendar.currentCalendar.components(NSCalendarUnit.DayCalendarUnit | NSCalendarUnit.MonthCalendarUnit | NSCalendarUnit.YearCalendarUnit, fromDate: m.endDate)
				if newComps.day == dateComps.day && newComps.month == dateComps.month && newComps.year == dateComps.year {
					morning = m
					break
				}
			}
			for e in evenings {
				let newComps = NSCalendar.currentCalendar.components(NSCalendarUnit.DayCalendarUnit | NSCalendarUnit.MonthCalendarUnit | NSCalendarUnit.YearCalendarUnit, fromDate: e.endDate)
				if newComps.day == dateComps.day && newComps.month == dateComps.month && newComps.year == dateComps.year {
					evening = e
					break
				}
			}
			for l in lowest {
				let newComps = NSCalendar.currentCalendar.components(NSCalendarUnit.DayCalendarUnit | NSCalendarUnit.MonthCalendarUnit | NSCalendarUnit.YearCalendarUnit, fromDate: l.endDate)
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
			case 0: break;
			case 1: break;
			case 2: break;
				/*morningValues = limitResults(morningValues, byFactor: 3)
				eveningValues = limitResults(eveningValues, byFactor: 3)
				lowestValues = limitResults(lowestValues, byFactor: 3)*/
			case 3:
				morningValues = limitResults(morningValues, byFactor: 9)
				eveningValues = limitResults(eveningValues, byFactor: 9)
				lowestValues = limitResults(lowestValues, byFactor: 9)
			case 4:
				morningValues = limitResults(morningValues, byFactor: 18)
				eveningValues = limitResults(eveningValues, byFactor: 18)
				lowestValues = limitResults(lowestValues, byFactor: 18)
			default: break;
		}

		dispatch_async(dispatch_get_main_queue()) {
			self.chartView.mornings = morningValues
			self.chartView.evenings = eveningValues
			if self.segments.selectedSegmentIndex < 2 {
				self.chartView.lowest = lowestValues
			} else {
				self.chartView.lowest = nil
			}
			self.chartView.drawCircles = self.segments.selectedSegmentIndex < 3
			self.chartView.drawDifferences = self.segments.selectedSegmentIndex < 3
			self.chartView.dataChanged()
		}

	}

	private func limitResults(_ values: NSArray, byFactor factor: Int) -> NSMutableArray { //TODO: drop _
		var result = NSMutableArray.arrayWithCapacity(values.count/factor)
		var i = 0
		while i < values.count {
			var average = 0.0
			var valueCount = 0
			for j in 0 ..< factor {
				let s = values[i]
				if s is HKQuantitySample {
					let q = s.quantity.doubleValueForUnit(DataAccess.weightUnit)
					average += q
					valueCount += 1
				}
				i += 1
			}
			if valueCount > 0 {
				let weight = HKQuantity.quantityWithUnit(DataAccess.weightUnit, doubleValue: average/valueCount)
				let dummySample = HKQuantitySample.quantitySampleWithType(DataAccess.weightQuantityType, quantity: weight, startDate: NSDate.date, endDate: NSDate.date, metadata: nil)
				result.addObject(dummySample)
			} else {
				result.addObject(NSNull.null)
			}
		}
		return result
	}

	private func clearResults() {
		dispatch_async(dispatch_get_main_queue()) {
			self.chartView.mornings = nil
			self.chartView.evenings = nil
			self.chartView.dataChanged()
		}
	}

}