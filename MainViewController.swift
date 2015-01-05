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
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Chart", style: .Plain, target: self, action: "showDetails:")
		#endif
		
		last.text = weightUnit.unitString
		bmi.text = "  "
		info.text = "  "
		newValue.becomeFirstResponder()
		
		let readTypes = NSSet.setWithObjects(weightQuantityType, heightQuantityType, dateOfBirthCharacteristicType, biologicalSexCharacteristicType, nil)
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
		//NSLog("date diff: %f", diff)
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
	
	func getAgeAndSex(callback: (Int, HKBiologicalSex) -> () = nil) {
		
		var error: NSError?
		var sex: HKBiologicalSex = .NotSet
		var bioSex = healthStore.biologicalSexWithError(&error)
		if error != nil {
			bioSex = nil;
			NSLog("error getting biological sex: %@", error)
		}
		else {
			sex = bioSex.biologicalSex
		}
		
			
		var dateOfBirth = healthStore.dateOfBirthWithError(&error)
		if error != nil {
			NSLog("error getting date of birth: %@", error)
		} else {

			var components = NSCalendar.currentCalendar.components(.NSYearCalendarUnit, fromDate: dateOfBirth, toDate: NSDate.date, options: 0)
			callback(components.year, sex)
		}
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
	
	public class var dateOfBirthCharacteristicType: HKCharacteristicType {
		return HKQuantityType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!
	}

	public class var biologicalSexCharacteristicType: HKCharacteristicType {
		return HKQuantityType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!
	}

	public class var weightUnit: HKUnit {
		get {
			
			switch NSUserDefaults.standardUserDefaults.integerForKey("WeightUnit") {
				case 1: // kg
					return HKUnit.gramUnitWithMetricPrefix(.Kilo)
				case 2: // lb
					return HKUnit.poundUnit
				default: // 0 = default
					if NSLocale.currentLocale.objectForKey(NSLocaleUsesMetricSystem).boolValue {
						return HKUnit.gramUnitWithMetricPrefix(.Kilo)
					} else {
						return HKUnit.poundUnit
					}			
			}
			
		}
	}
	
	public func getBMI(callback: (Double, String) -> () = nil) {

		getWeight() { weight in 

			if navigationItem.rightBarButtonItem == nil {
				navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Chart", style: .Plain, target: self, action: "showDetails:")
			}

			getHeight() { height in 

				let weightInKg = weight.quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
				let heightInM = height.quantity.doubleValueForUnit(HKUnit.meterUnit)
				let bmiValue = calculateBMIFromWeight(weightInKg, height: heightInM)
				//NSLog("weight: %f, height: %f, bmi: %f", weightInKg, heightInM, bmi)
				bmi.text = NSString.stringWithFormat("Your BMI is %0.2f.", bmiValue)
				
				getAgeAndSex() { age, sex in
				
					var effectiveBmiValue = bmiValue
				
					if age > 18 || age == -1{

						//
						// adjust for females, based on http://www.bmi-rechner.net
						//
						if sex == HKBiologicalSex.Female {
							if effectiveBmiValue < 28 { // anything below 30 is one less for females
								effectiveBmiValue++;
							}
						}
						 
						//
						// adjust for age, based on http://www.bmi-rechner.net
						//
						if age <= 24 {
							effectiveBmiValue++;
						} else if age <= 34 {
							// keep
						} else if age <= 44 {
							effectiveBmiValue -= 1;
						} else if age <= 54 {
							effectiveBmiValue -= 2;
						} else if age <= 64 {
							effectiveBmiValue -= 3;
						} else {
							effectiveBmiValue -= 4;
						}
						
						NSLog("effectiveBmiValue: %f", effectiveBmiValue)
						
						var label = "";   
						var level = 0;
						if effectiveBmiValue < 16 {
							label = "Severely Underweight"
						} else if effectiveBmiValue <= 17 {
							label = "Moderately Underweight"
						} else if effectiveBmiValue <= 18.5 {
							label = "Slightly Underweight"
							level = 1
						} else if effectiveBmiValue <= 25 {
							label = "Normal"
							level = 2
						} else if effectiveBmiValue <= 30 {
							label = "Overweight"
							level = 1
						} else if effectiveBmiValue <= 35 {
							label = "Obese Class I"
						} else if effectiveBmiValue <= 40 {
							label = "Obese Class II"
						} else {
							label = "Extremely Obese Class III"
						}
						info.text = label;
						switch level {
							case 0:
							default:
								info.textColor = UIColor.redColor
							case 1:
								info.textColor = UIColor.colorWithRed(0.75, green: 0.75, blue: 0, alpha: 1.0)
							case 2:
								info.textColor = UIColor.colorWithRed(0, green: 0.5, blue: 0, alpha: 1.0)
						}
					} else {
						
					}
				
				}
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
	@IBOutlet weak var bmi: UILabel! 
	@IBOutlet weak var info: UILabel! 
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
