import UIKit
import HealthKit

@IBObject class MainViewController : UIViewController {

	public override func viewDidLoad() {

		super.viewDidLoad()
		navigationController.navigationBar.barTintColor = UIColor.colorWithRed(0.75, green: 0.0, blue: 0.0, alpha: 1.0)
		let attributes = NSMutableDictionary()
		attributes[NSForegroundColorAttributeName] = UIColor.colorWithRed(1.0, green: 1.0, blue: 1.0, alpha: 1.0)
		navigationController.navigationBar.titleTextAttributes = attributes
		
		last.text = ""
		newValue.becomeFirstResponder()
		
		let types = NSSet.setWithObject(weightQuantityType)
		healthStore.requestAuthorizationToShareTypes(types, readTypes: types, completion: { success, error in 
			if let e = error {
				NSLog("error: %@", error)
			} else {
				updateInfo()
				healthStore.executeQuery(observerQuery)
			}
		})
		title = "Weight"
	}
	
	func relativeStringForDate(date: NSDate) -> String {
		
		let comps = NSCalendar.currentCalendar.components(NSCalendarUnit.Day|NSCalendarUnit.Month.Year, fromDate: date)
		let nowComps = NSCalendar.currentCalendar.components(NSCalendarUnit.Day|NSCalendarUnit.Month.Year, fromDate: NSDate.date)
		let diff = -date.timeIntervalSinceNow
		if diff < 5*60 {
			return "just now"
		}
		if diff < 24*60*60 && comps.day == nowComps.day {
			return "earlier today"
		}
		let df = NSDateFormatter()
		df.doesRelativeDateFormatting = true
		df.dateStyle = NSDateFormatterStyle.NSDateFormatterMediumStyle
		return df.stringFromDate(date).lowercaseString
	}
	
	func updateInfo() {
		
		let descriptor = NSSortDescriptor.sortDescriptorWithKey(HKSampleSortIdentifierEndDate, ascending: false)
		let q = HKSampleQuery(sampleType: weightQuantityType, 
							  predicate: nil, 
							  limit: 1, 
							  sortDescriptors: [descriptor],
							  resultsHandler: { (explicit: HKSampleQuery!, results: NSArray?, error: NSError?) in 
							  
			if let e = error {
				NSLog("error: %@", error)
			} else {
				if results?.count > 0 {
					dispatch_async(dispatch_get_main_queue()) {
						last.text = NSString.stringWithFormat("Last was %@, %@.", results![0].quantity, relativeStringForDate(results![0].endDate)) 
					}
				}
			}
		})   
				
		healthStore.executeQuery(q)	
	}
	
	//
	// Properties
	//
	
	private let healthStore = HKHealthStore() 
	
	private let observerQuery: HKObserverQuery = HKObserverQuery(sampleType: weightQuantityType, 
														 predicate: nil,
														 updateHandler: { (explicit: HKObserverQuery!, handler: HKObserverQueryCompletionHandler, error: NSError?) in
		if let e = error {
			NSLog("error: %@", error)
		} else {
			updateInfo()
		}
	})	

	private var weightQuantityType: HKQuantityType {
		get {
			let identifier = HKQuantityTypeIdentifierBodyMass
			return HKQuantityType.quantityTypeForIdentifier(identifier)!
		}
	}
	
	//
	// Outlets
	//
	
	@IBOutlet weak var last: UILabel! 
	@IBOutlet weak var newValue: UITextField!
	
	//
	// Actions
	//
	
	@IBAction func add(sender: Any?) {
		
		if newValue.text.doubleValue < 10 {
			return
		}
		
		let date = NSDate.date		
		let weight = HKQuantity.quantityWithUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo), doubleValue: newValue.text.doubleValue)
		let sample = HKQuantitySample.quantitySampleWithType(weightQuantityType, quantity: weight, startDate: date, endDate: date, metadata: NSMutableDictionary())
		
		healthStore.saveObject(sample, withCompletion: { (success: Bool, error: NSError?) in
		
			if let e = error {
				NSLog("error: %@", error)
			} else {
				NSLog("value added.")
				dispatch_async(dispatch_get_main_queue()) {
					newValue.text = ""
				}
				updateInfo()
			}
			
		})  
	}
}
