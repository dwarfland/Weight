import UIKit
import HealthKit

@IBObject class MainViewController : UIViewController {

	public override func viewDidLoad() {

		super.viewDidLoad()
		navigationController.navigationBar.tintColor = UIColor.colorWithRed(1.0, green: 0.75, blue: 0.75, alpha: 1.0)
		navigationController.navigationBar.barTintColor = UIColor.colorWithRed(0.75, green: 0.0, blue: 0.0, alpha: 1.0)
		let attributes = NSMutableDictionary()
		attributes[NSForegroundColorAttributeName] = UIColor.colorWithRed(1.0, green: 1.0, blue: 1.0, alpha: 1.0)
		navigationController.navigationBar.titleTextAttributes = attributes

		#if TARGET_IPHONE_SIMULATOR
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "History", style: .Plain, target: self, action: "showDetails:")
		#endif
		
		last.text = weightUnit.unitString
		newValue.becomeFirstResponder()
		
		let readTypes = NSSet.setWithObjects(weightQuantityType, heightQuantityType, nil)
		let writeTypes = NSSet.setWithObjects(weightQuantityType, bmiQuantityType, nil)
		healthStore.requestAuthorizationToShareTypes(writeTypes, readTypes: readTypes, completion: { success, error in 
			if let e = error {
				NSLog("error: %@", error)
			} else {
				getBMI() // temp for testing
				//updateInfo()
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
	
	private var cachedWeight: HKQuantitySample?
	func getWeight(callback: (HKQuantitySample) -> () = nil) {
		
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
						cachedWeight = results![0];
						if callback != nil { 
							callback(cachedWeight!) 
						}
					}
				}
			}
		})   
				
		healthStore.executeQuery(q)	
	}
	
	private var cachedHeight: HKQuantitySample?
	func getHeight(callback: (HKQuantitySample) -> () = nil) {
		
		let descriptor = NSSortDescriptor.sortDescriptorWithKey(HKSampleSortIdentifierEndDate, ascending: false)
		let q = HKSampleQuery(sampleType: heightQuantityType, 
							  predicate: nil, 
							  limit: 1, 
							  sortDescriptors: [descriptor],
							  resultsHandler: { (explicit: HKSampleQuery!, results: NSArray?, error: NSError?) in 
							  
			if let e = error {
				NSLog("error: %@", error)
			} else {
				if results?.count > 0 {
					dispatch_async(dispatch_get_main_queue()) {
						cachedHeight = results![0];
						if callback != nil { 
							callback(cachedHeight!) 
						}
					}
				}
			}
		})   
				
		healthStore.executeQuery(q)	
	}

	//
	// Properties
	//
	
	public class let healthStore: HKHealthStore = HKHealthStore() 
	
	private let observerQuery: HKObserverQuery = HKObserverQuery(sampleType: weightQuantityType, 
														 predicate: nil,
														 updateHandler: { (explicit: HKObserverQuery!, handler: HKObserverQueryCompletionHandler, error: NSError?) in
		if let e = error {
			NSLog("error: %@", error)
		} else {
			getBMI()
		}
	})	

	public class var weightQuantityType: HKQuantityType {
		return HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
	}
	
	public class var heightQuantityType: HKQuantityType {
		return HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!
	}
	
	public class var bmiQuantityType: HKQuantityType {
		return HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!
	}

	public class var weightUnit: HKUnit {
		get {
			if NSLocale.currentLocale.objectForKey(NSLocaleUsesMetricSystem).boolValue {
				return HKUnit.gramUnitWithMetricPrefix(.Kilo)
			} else {
				return HKUnit.poundUnit
			}			
		}
	}
	
	public func getBMI(callback: (Double, String) -> () = nil) {

		getWeight() { weight in 

			if navigationItem.rightBarButtonItem == nil {
				navigationItem.rightBarButtonItem = UIBarButtonItem(title: "History", style: .Plain, target: self, action: "showDetails:")
			}

			getHeight() { height in 

				let weightInKg = weight.quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
				let heightInM = height.quantity.doubleValueForUnit(HKUnit.meterUnit)
				let bmi = calculateBMIFromWeight(weightInKg, height: heightInM)
				//NSLog("weight: %f, height: %f, bmi: %f", weightInKg, heightInM, bmi)
				last.text = NSString.stringWithFormat("%0.1f%@, %@ (BMI %0.2f).", weight.quantity.doubleValueForUnit(weightUnit), weightUnit.unitString, relativeStringForDate(weight.endDate), bmi)
			}
			last.text = NSString.stringWithFormat("%0.1f%@, %@.", weight.quantity.doubleValueForUnit(weightUnit), weightUnit.unitString, relativeStringForDate(weight.endDate)) 
		}
	}
	
	func calculateBMIFromWeight(weight: Double, height: Double) -> Double {
		return weight / (height*height)
	}
	
	/*public lazy class var weightQuantityType: HKQuantityType! = {  // bugs:69465: Silver: lazy proper should not require to be nullable?
		let identifier = HKQuantityTypeIdentifierBodyMass
		return HKQuantityType.quantityTypeForIdentifier(identifier)!
	}()
	
	public lazy class var weightUnit: HKUnit! = { // bugs:69465: Silver: lazy proper should not require to be nullable?
		if NSLocale.currentLocale.objectForKey(NSLocaleUsesMetricSystem).boolValue {
			return HKUnit.gramUnitWithMetricPrefix(.Kilo)
		} else {
			return HKUnit.poundUnit
		}			
	}()*/
	
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
		let weight = HKQuantity.quantityWithUnit(weightUnit, doubleValue: newValue.text.stringByReplacingOccurrencesOfString(",", withString:".").doubleValue)
		let sample = HKQuantitySample.quantitySampleWithType(weightQuantityType, quantity: weight, startDate: date, endDate: date, metadata: NSMutableDictionary())
		
		getHeight() {height in
			let weightInKg = weight.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
			let heightInM = height.quantity.doubleValueForUnit(HKUnit.meterUnit)
			let bmi = calculateBMIFromWeight(weightInKg, height: heightInM)
			
			let bmiQuantity = HKQuantity.quantityWithUnit(HKUnit.countUnit, doubleValue: bmi)
			let bmisample = HKQuantitySample.quantitySampleWithType(bmiQuantityType, quantity: bmiQuantity, startDate: date, endDate: date, metadata: NSMutableDictionary())
			healthStore.saveObject(bmisample, withCompletion: { (success: Bool, error: NSError?) in
				if let e = error {
					NSLog("error updating BMI: %@", error)
				}
			})
		}
		
		healthStore.saveObject(sample, withCompletion: { (success: Bool, error: NSError?) in
		
			if let e = error {
				NSLog("error updating weight: %@", error)
			} else {
				dispatch_async(dispatch_get_main_queue()) {
					newValue.text = ""
					//performSegueWithIdentifier("ShowDetails", sender: nil) //TESTCASE for 69436: Silver CC: CC shows wrong multipart method names
				}
				getBMI()
			}
			
		})  
	}
	
	@IBAction func showDetails(sendr: Any?) {
		performSegueWithIdentifier("ShowDetails", sender: nil)
	}
}
