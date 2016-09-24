import Foundation
import HealthKit

let MAX_DAYS = 10000

typealias WeightDataCallback = (CollectedWeightData?) -> ()

public class DataAccess {

	public static let healthStore: HKHealthStore = HKHealthStore() 

	public static var weightQuantityType: HKQuantityType {
		return HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
	}
	
	public static var weightUnit: HKUnit {
		get {
			
			switch NSUserDefaults.standardUserDefaults.integerForKey("WeightUnit") {
				case 1: // kg
					return HKUnit.gramUnitWithMetricPrefix(.Kilo)
				case 2: // lb
					return HKUnit.poundUnit
				default: // 0 = default
					if NSLocale.currentLocale.objectForKey(NSLocaleUsesMetricSystem)!.boolValue {
						return HKUnit.gramUnitWithMetricPrefix(.Kilo)
					} else {
						return HKUnit.poundUnit
					}			
			}
			
		}
	}
	
	static let sharedInstance = DataAccess()

	func getData(# days: Int, callback: (CollectedWeightData?) -> () ) { 

		//NSLog("1")
		//NSLog("callback %@", callback)
		callback.copy()
		//NSLog("callback %@", callback)
		let descriptor = NSSortDescriptor.sortDescriptorWithKey(HKSampleSortIdentifierEndDate, ascending: false)
		let q = HKSampleQuery(sampleType: weightQuantityType, 
							  predicate: nil, 
							  limit: MAX_DAYS*4, 
							  sortDescriptors: [descriptor],
							  resultsHandler: { (explicit: HKSampleQuery!, results: NSArray?, error: NSError?) in 
							  
			/*NSLog("2")
			if let e = error {
				NSLog("error: %@", error)
				NSLog("calling back with nil (a)")
				callback(nil)
			} else {
				NSLog("3")
				if results?.count > 0 {
					//callback(results)*/
					//NSLog("calling processResults")
					self.process(results: results!, daysNeeded: days, callback: callback)
				/*} else {
					NSLog("calling back with nil (b)")
					callback(nil)
				}
			}*/
		})   
				
		DataAccess.healthStore.executeQuery(q) 
	}
	
	func process(results values: NSArray, daysNeeded: Int, callback: (CollectedWeightData?) -> ()) {
		
		//NSLog("processResults")
		
		var mornings = NSMutableArray.arrayWithCapacity(daysNeeded)
		var evenings = NSMutableArray.arrayWithCapacity(daysNeeded)
		var lowest = NSMutableArray.arrayWithCapacity(daysNeeded)
		var lastValue: HKQuantitySample?
		var lowestValue: HKQuantitySample?
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
				if lowestValue != nil {
					lowest.addObject(lowestValue!)
					lowestValue = nil
				} else {
					// first value ever
				}
				evenings.addObject(val)
			}
			lastValue = val
			if lowestValue == nil || lowestValue!.quantity.doubleValueForUnit(weightUnit) > val.quantity.doubleValueForUnit(weightUnit) {
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
		
		var data = CollectedWeightData(morningValues: morningValues, eveningValues: eveningValues, lowestValues: lowestValues)
		//NSLog("processResults done")
		//NSLog("data in processResults: %@", data)
		callback(data)
		
	}
}

public class CollectedWeightData {
	

	var morningValues: NSArray
	var eveningValues: NSArray
	var lowestValues: NSArray
	
	init(morningValues: NSArray, eveningValues: NSArray, lowestValues: NSArray) {
		self.morningValues = morningValues;
		self.eveningValues = eveningValues;
		self.lowestValues = lowestValues;
	}

	func limitDataForSelection(selectedSegmentIndex: Int) {
		switch selectedSegmentIndex {
			case 2: 
				morningValues = limitResults(morningValues, byFactor: 3)
				eveningValues = limitResults(eveningValues, byFactor: 3)
				lowestValues = limitResults(lowestValues, byFactor: 3)
			case 3: 
				morningValues = limitResults(morningValues, byFactor: 9)
				eveningValues = limitResults(eveningValues, byFactor: 9)
				lowestValues = limitResults(lowestValues, byFactor: 9)
			default:
		}
	}
		
	private static func limitResults(_ values: NSArray, byFactor factor: Int) -> NSMutableArray { //TODO: drop _
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

}