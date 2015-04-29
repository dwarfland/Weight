import UIKit
import HealthKit

@IBObject class MainViewController : UIViewController {

	public override func viewDidLoad() {

		super.viewDidLoad()
		
		navigationController.navigationBar.tintColor = UIColor.colorWithRed(1.0, green: 0.75, blue: 0.75, alpha: 1.0)
		navigationController.navigationBar.barTintColor = UIColor.colorWithRed(0.75, green: 0.0, blue: 0.0, alpha: 1.0)
		
		navigationController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.colorWithRed(1.0, green: 1.0, blue: 1.0, alpha: 1.0)]

		#if TARGET_IPHONE_SIMULATOR
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Chart", style: .Plain, target: self, action: "showDetails:")
		#endif
		
		last.text = DataAccess.weightUnit.unitString
		bmi.text = "  "
		info.text = "  "
		newValue.becomeFirstResponder()
		
		let readTypes = NSSet.setWithObjects(DataAccess.weightQuantityType, heightQuantityType, dateOfBirthCharacteristicType, biologicalSexCharacteristicType, nil)
		let writeTypes = NSSet.setWithObjects(DataAccess.weightQuantityType, bmiQuantityType, nil)
		DataAccess.healthStore.requestAuthorizationToShareTypes(writeTypes, readTypes: readTypes, completion: { success, error in 

			if let e = error {
				NSLog("error: %@", error)
			} else {
				self.getBMI()
				DataAccess.healthStore.executeQuery(self.observerQuery)
			}
		})
		title = "Weight"
		
		//view.addGestureRecognizer(UISwipeGestureRecognizer());
	}
	
	func relativeStringForDate(date: NSDate) -> String {
		
		NSLog("relativeStringForDate start")
		let comps = NSCalendar.currentCalendar.components(NSCalendarUnit.DayCalendarUnit|NSCalendarUnit.MonthCalendarUnit|NSCalendarUnit.YearCalendarUnit, fromDate: date)
		let nowComps = NSCalendar.currentCalendar.components(NSCalendarUnit.DayCalendarUnit|NSCalendarUnit.MonthCalendarUnit|NSCalendarUnit.YearCalendarUnit, fromDate: NSDate.date)
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
		NSLog("relativeStringForDate almost end")
		NSLog("df.stringFromDate(date).lowercaseString %@", df.stringFromDate(date).lowercaseString)
		return df.stringFromDate(date).lowercaseString
		NSLog("relativeStringForDate end")
	}
	
	private var cachedWeight: HKQuantitySample?
	func getWeight(callback: (HKQuantitySample) -> () = nil) {
		
		NSLog("getWeight start")
		let descriptor = NSSortDescriptor.sortDescriptorWithKey(HKSampleSortIdentifierEndDate, ascending: false)
		let q = HKSampleQuery(sampleType: DataAccess.weightQuantityType, 
							  predicate: nil, 
							  limit: 1, 
							  sortDescriptors: [descriptor],
							  resultsHandler: { (explicit: HKSampleQuery!, results: NSArray?, error: NSError?) in 
							  
			if let e = error {
				NSLog("error: %@", error)
			} else {
				if results?.count > 0 {
					dispatch_async(dispatch_get_main_queue()) {
						self.cachedWeight = results![0];
						if callback != nil { 
							callback(self.cachedWeight!) 
						}
					}
				}
			}
		})   
				
		DataAccess.healthStore.executeQuery(q)	
		NSLog("getWeight end")
	}
	
	private var cachedHeight: HKQuantitySample?
	func getHeight(callback: (HKQuantitySample) -> () = nil) {
		
		NSLog("getHeight start")
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
						self.cachedHeight = results![0];
						if callback != nil { 
							callback(self.cachedHeight!) 
						}
					}
				}
			}
		})   
				
		DataAccess.healthStore.executeQuery(q)	
		NSLog("getHeight end")
	}
	
	func getAgeAndSex(callback: (Int, HKBiologicalSex) -> () = nil) {
		
		NSLog("getAgeAndSex start")
		var error: NSError?
		var sex: HKBiologicalSex = .NotSet
		var bioSex = DataAccess.healthStore.biologicalSexWithError(&error)
		if error != nil {
			bioSex = nil;
			NSLog("error getting biological sex: %@", error)
		}
		else {
			sex = bioSex.biologicalSex
		}
			
		var dateOfBirth = DataAccess.healthStore.dateOfBirthWithError(&error)
		if error != nil {
			NSLog("error getting date of birth: %@", error)
		} else {

			var components = NSCalendar.currentCalendar.components(.NSYearCalendarUnit, fromDate: dateOfBirth, toDate: NSDate.date, options: 0)
			callback(components.year, sex)
		}
		NSLog("getAgeAndSex end")
	}

	//
	// Properties
	//
	
	private let observerQuery: HKObserverQuery = HKObserverQuery(sampleType: DataAccess.weightQuantityType, 
														 predicate: nil,
														 updateHandler: { (explicit: HKObserverQuery!, handler: HKObserverQueryCompletionHandler, error: NSError?) in
		if let e = error {
			NSLog("error: %@", error)
		} else {
			self.getBMI()
		}
	})	

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

	public func getBMI(callback: (Double, String) -> () = nil) {

		NSLog("getBMI start")
		getWeight() { weight in 

			NSLog("getWeight callback start")
			if self.navigationItem.rightBarButtonItem == nil {
				self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Chart", style: .Plain, target: self, action: "showDetails:")
			}

			NSLog("getWeight callback before setlabel")
			self.last.text = NSString.stringWithFormat("%0.1f%@, %@.", weight.quantity.doubleValueForUnit(DataAccess.weightUnit), DataAccess.weightUnit.unitString, self.relativeStringForDate(weight.endDate)) 
			NSLog("getWeight callback after setlabel")

			self.getHeight() { height in 

				NSLog("getHeight callback start")
				let weightInKg = weight.quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
				let heightInM = height.quantity.doubleValueForUnit(HKUnit.meterUnit)
				let bmiValue = self.calculateBMIFromWeight(weightInKg, height: heightInM)
				NSLog("getHeight callback before setlabel")
				self.bmi.text = NSString.stringWithFormat("Your BMI is %0.2f.", bmiValue)
				NSLog("getHeight callback after setlabel")
				
				self.getAgeAndSex() { age, sex in
				
					NSLog("getAgeAndSex callback start")
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
						self.info.text = label;
						switch level {
							case 1:
								self.info.textColor = UIColor.colorWithRed(0.75, green: 0.75, blue: 0, alpha: 1.0)
							case 2:
								self.info.textColor = UIColor.colorWithRed(0, green: 0.5, blue: 0, alpha: 1.0)
							case 0:
								fallthrough
							default:
								self.info.textColor = UIColor.redColor
						}
					} else {
						//ToDo: handle BMI for kids?
					}
					NSLog("getAgeAndSex callback end")
				
				}
				NSLog("getHeight callback end")
			}
			NSLog("getWeight callback end")
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
		let weight = HKQuantity.quantityWithUnit(DataAccess.weightUnit, doubleValue: newValue.text.stringByReplacingOccurrencesOfString(",", withString:".").doubleValue)
		let sample = HKQuantitySample.quantitySampleWithType(DataAccess.weightQuantityType, quantity: weight, startDate: date, endDate: date, metadata: NSMutableDictionary())
		
		getHeight() {height in
			let weightInKg = weight.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
			let heightInM = height.quantity.doubleValueForUnit(HKUnit.meterUnit)
			let bmi = self.calculateBMIFromWeight(weightInKg, height: heightInM)
			
			let bmiQuantity = HKQuantity.quantityWithUnit(HKUnit.countUnit, doubleValue: bmi)
			let bmisample = HKQuantitySample.quantitySampleWithType(self.bmiQuantityType, quantity: bmiQuantity, startDate: date, endDate: date, metadata: NSMutableDictionary())
			DataAccess.healthStore.saveObject(bmisample, withCompletion: { (success: Bool, error: NSError?) in
				if let e = error {
					NSLog("error updating BMI: %@", error)
				}
			})
		}
		
		DataAccess.healthStore.saveObject(sample, withCompletion: { (success: Bool, error: NSError?) in
		
			if let e = error {
				NSLog("error updating weight: %@", error)
			} else {
				dispatch_async(dispatch_get_main_queue()) {
					self.newValue.text = ""
					//performSegueWithIdentifier("ShowDetails", sender: nil) //TESTCASE for 69436: Silver CC: CC shows wrong multipart method names
				}
				self.getBMI()
			}
			
		})  
	}
	
	@IBAction func showDetails(sendr: Any?) {
		performSegueWithIdentifier("ShowDetails", sender: nil)
	}
}
