import UIKit
import HealthKit

@IBObject class MainViewController : UIViewController {

	public override func viewDidLoad() {

		super.viewDidLoad()
		//navigationController.navigationBar.tintColor := UIColor.colorWithRed(0.8) green(0.8) blue(1.0) alpha(1.0)
		navigationController.navigationBar.barTintColor = UIColor.colorWithRed(0.75, green: 0, blue: 0, alpha: 1.0)
		let attributes = NSMutableDictionary()
		attributes[NSForegroundColorAttributeName] = UIColor.colorWithRed(1.0, green: 1.0, blue: 1.0, alpha: 1.0)
		navigationController.navigationBar.titleTextAttributes = attributes
		
		last.text = ""
		newValue.becomeFirstResponder()
		
		let types = NSSet.setWithObject(weightQuantityType)
		healthStore.requestAuthorizationToShareTypes(types, readTypes: types, completion: { (success: Bool, error: NSError?) in 
			if let e = error {
				NSLog("error: %@", error)
			} else {
				NSLog("auhtorized")
				updateInfo()
				healthStore.executeQuery(observerQuery)
			}
		})
		title = "Weight"
	}
	
	public override func didReceiveMemoryWarning() {

		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
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
		return df.stringFromDate(date).lowercaseString!  // bug: shouild not need !
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
				NSLog("results: %@", results)
				if results?.count > 0 {
					dispatch_async(dispatch_get_main_queue()) {
						last.text = NSString.stringWithFormat("Last was %@, %@.", results![0].quantity, relativeStringForDate(results![0].endDate!)) // bug: shoud not need !
					}
				}
			}
		})	
		
		healthStore.executeQuery(q)	
	}
	
	var healthStore = HKHealthStore() 
	
	var observerQuery: HKObserverQuery = HKObserverQuery(sampleType: weightQuantityType, 
														 predicate: nil,
														 updateHandler: { (explicit: HKObserverQuery!, handler: HKObserverQueryCompletionHandler, error: NSError?) in
		if let e = error {
			NSLog("error: %@", error)
		} else {
			NSLog("updated!")
			updateInfo()
		}
	})	

	var weightQuantityType: HKQuantityType {
		get {
			let identifier = HKQuantityTypeIdentifierBodyMass
			return HKQuantityType.quantityTypeForIdentifier(identifier)!
		}
	}
	
	
	
	@IBOutlet weak var last: UILabel! 
	@IBOutlet weak var newValue: UITextField!
	
	@IBAction func add(sender: Any?) {
		
		if newValue.text.doubleValue < 10 {
			return
		}
		
		let weight = HKQuantity.quantityWithUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo), doubleValue: newValue.text.doubleValue)
		let meta = NSMutableDictionary()
		//meta[HKMetadataKeyBodyMass] = KLBodyMassSensor
		let date = NSDate.date
		
		let sample = HKQuantitySample.quantitySampleWithType(weightQuantityType, quantity: weight, startDate: date, endDate: date, metadata: meta)
		
		healthStore.saveObject(sample, withCompletion: { (success: Bool, error: NSError?) in
		
			if let e = error {
				NSLog("error: %@", error)
			} else {
				NSLog("value added.")
				newValue.text = ""
				updateInfo()
			}
			
		})
		
	}

}
