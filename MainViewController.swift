import UIKit
import HealthKit

@IBObject class MainViewController : UIViewController {

	public override func viewDidLoad() {

		super.viewDidLoad()

		navigationController?.navigationBar?.tintColor = UIColor.colorWithRed(1.0, green: 0.75, blue: 0.75, alpha: 1.0)
		navigationController?.navigationBar?.barTintColor = UIColor.colorWithRed(0.75, green: 0.0, blue: 0.0, alpha: 1.0)

		#if TARGET_IPHONE_SIMULATOR
		addChartButton()
		#endif

		let cachedWeight = NSUserDefaults.standardUserDefaults.floatForKey(CACHED_LAST_WEIGHT_VALUE_KEY)
		if cachedWeight > 0 {
			last.text = NSString.stringWithFormat("%0.1f%@, cached.", cachedWeight, DataAccess.weightUnit.unitString)
			addChartButton()
		} else {
			last.text = DataAccess.weightUnit.unitString
		}

		if #available(iOS 13.0) {
			self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.systemImageNamed("ellipsis.circle"), style: .Plain, target: self, action: #selector(showActions:))
		} else {
			self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "...", style: .Plain, target: self, action: #selector(showActions:))
		}

		bmi.text = "  "
		info.text = "  "
		newValue.becomeFirstResponder()
		weightEditChanged(nil)

		let readTypes = NSSet.setWithObjects(DataAccess.weightQuantityType, heightQuantityType, dateOfBirthCharacteristicType, biologicalSexCharacteristicType, nil)
		let writeTypes = NSSet.setWithObjects(DataAccess.weightQuantityType, bmiQuantityType, nil)
		DataAccess.healthStore.requestAuthorizationToShareTypes(writeTypes, readTypes: readTypes, completion: { success, error in

			if let e = error {
				NSLog("error: %@", error)
			} else {
				self.getBMI()
				//updateInfo()
				//DataAccess.healthStore.executeQuery(self.observerQuery)
			}
		})
		title = "Weight"

		//view.addGestureRecognizer(UISwipeGestureRecognizer());
	}

	let CACHED_LAST_WEIGHT_VALUE_KEY = "CACHED_LAST_WEIGHT_VALUE"

	func relativeStringForDate(_ date: NSDate) -> String {

		let diff = -date.timeIntervalSinceNow
		if diff < 5*60 {
			return "just now"
		}
		if NSCalendar.currentCalendar.isDateInToday(date) {
			return "earlier today"
		}
		if NSCalendar.currentCalendar.isDateInYesterday(date) {
			return "yesterday"
		}
		let df = NSDateFormatter()
		df.doesRelativeDateFormatting = true
		df.dateStyle = NSDateFormatterStyle.NSDateFormatterMediumStyle
		return df.stringFromDate(date).lowercaseString
	}

	private var getWeightVersion: Int = 0
	private var cachedWeight: HKQuantitySample?

	func getWeight(callback: ((HKQuantitySample) -> ())? = nil) {

		getWeightVersion += 1
		let currentGetWeightVersion = getWeightVersion;
		let date = NSDate.date;

		let descriptor = NSSortDescriptor.sortDescriptorWithKey(HKSampleSortIdentifierEndDate, ascending: false)
		let q = HKSampleQuery(sampleType: DataAccess.weightQuantityType,
							  predicate: nil,
							  limit: 1,
							  sortDescriptors: [descriptor],
							  resultsHandler: { (explicit: HKSampleQuery!, results: NSArray?, error: NSError?) in

			NSLog("-- getWeight took %f", -date.timeIntervalSinceNow);

			if currentGetWeightVersion != self.getWeightVersion {
				NSLog("skipping weight update because newer one is pending.")
				return
			}

			if let e = error {
				NSLog("error: %@", error)
			} else {
				if results?.count > 0 {
					dispatch_async(dispatch_get_main_queue()) {
						self.cachedWeight = results![0];
						self.weightEditChanged(nil)
						if callback != nil {
							callback(self.cachedWeight!)
						}
					}
				}
			}
		})

		DataAccess.healthStore.executeQuery(q)
	}

	private var getHeightVersion: Int = 0
	private var cachedHeight: HKQuantitySample?
	func getHeight(callback: ((HKQuantitySample) -> ())? = nil) {

		self.getHeightVersion += 1
		let currentGetHeightVersion = self.getHeightVersion;

		let descriptor = NSSortDescriptor.sortDescriptorWithKey(HKSampleSortIdentifierEndDate, ascending: false)
		let q = HKSampleQuery(sampleType: heightQuantityType,
							  predicate: nil,
							  limit: 1,
							  sortDescriptors: [descriptor],
							  resultsHandler: { (explicit: HKSampleQuery!, results: NSArray?, error: NSError?) in

			if currentGetHeightVersion != self.getHeightVersion {
				NSLog("skipping height update because newer one is pending.")
				return
			}

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
	}

	func getAgeAndSex(callback: ((Int, HKBiologicalSex) -> ())? = nil) {

		var error: NSError? = nil
		var sex: HKBiologicalSex = .NotSet
		var bioSex = DataAccess.healthStore.biologicalSexWithError(&error)
		if error != nil {
			bioSex = nil;
			NSLog("error getting biological sex: %@", error)
		} else if bioSex == nil {
			NSLog("biological sex not set.")
		} else {
			sex = bioSex!.biologicalSex
		}

		var dateOfBirth = DataAccess.healthStore.dateOfBirthWithError(&error)
		if error != nil {
			NSLog("error getting date of birth: %@", error)
		} else if dateOfBirth == nil {
			NSLog("date of birth not set.")
		} else {
			var components = NSCalendar.currentCalendar.components(.NSYearCalendarUnit, fromDate: dateOfBirth!, toDate: NSDate.date, options: 0)
			callback(components.year, sex)
		}
	}

	//
	// Properties
	//

	/*private let observerQuery: HKObserverQuery = HKObserverQuery(sampleType: DataAccess.weightQuantityType,
														 predicate: nil,
														 updateHandler: { (explicit: HKObserverQuery!, handler: HKObserverQueryCompletionHandler, error: NSError?) in
		if let e = error {
			NSLog("error: %@", error)
		} else {
			self.getBMI()
		}
	}) */

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

	func addChartButton() {
		if self.navigationItem.rightBarButtonItem == nil {
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Chart", style: .Plain, target: self, action: #selector(showDetails:))
		}
	}

	public func getBMI(callback: ((Double, String) -> ())? = nil) {

		getWeight() { weight in

			self.addChartButton()

			self.last.text = NSString.stringWithFormat("%0.1f%@, %@.", weight.quantity.doubleValueForUnit(DataAccess.weightUnit), DataAccess.weightUnit.unitString, self.relativeStringForDate(weight.endDate))
			NSUserDefaults.standardUserDefaults.setFloat(weight.quantity.doubleValueForUnit(DataAccess.weightUnit), forKey: self.CACHED_LAST_WEIGHT_VALUE_KEY)

			self.bmi.text = "  "
			self.info.text = "  "

			self.getHeight() { height in

				let weightInKg = weight.quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
				if weightInKg > 10 {

					let heightInM = height.quantity.doubleValueForUnit(HKUnit.meterUnit)
					let bmiValue = self.calculateBMIFrom(weight: weightInKg, height: heightInM)
					self.bmi.text = NSString.stringWithFormat("Your BMI is %0.2f.", bmiValue)
					self.info.text = "  "

					self.getAgeAndSex() { age, sex in

						var effectiveBmiValue = bmiValue

						if age > 18 || age == -1 {

							//
							// adjust for females, based on http://www.bmi-rechner.net
							//
							if sex == HKBiologicalSex.Female {
								if effectiveBmiValue < 28 { // anything below 30 is one less for females
									effectiveBmiValue += 1;
								}
							}

							//
							// adjust for age, based on http://www.bmi-rechner.net
							//
							if age <= 24 {
								effectiveBmiValue += 1;
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

							//NSLog("effectiveBmiValue: %f", effectiveBmiValue)

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
					}
				}
			}
		}
	}

	func calculateBMIFrom(weight: Double, height: Double) -> Double {
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
	@IBOutlet weak var addButton: UIButton!

	//
	// Actions
	//

	@IBAction func weightEditChanged(_ sender: Any?) {

		if let text = newValue.text {

			if text.doubleValue < 10 {
				addButton.hidden = false
				addButton.alpha = 0.25
				return
			}

			let enteredWeight = text.stringByReplacingOccurrencesOfString(",", withString:".").doubleValue

			var oldWeight = NSUserDefaults.standardUserDefaults.floatForKey(CACHED_LAST_WEIGHT_VALUE_KEY)
			if let oldWeightSample = cachedWeight {
				oldWeight = oldWeightSample.quantity.doubleValueForUnit(DataAccess.weightUnit)
			}

			if oldWeight > 10 && enteredWeight > 99 {
				let potentialNewWeight = enteredWeight/10
				if oldWeight-potentialNewWeight > -10 && oldWeight-potentialNewWeight < 10 {
					newValue.text = NSString.stringWithFormat("%0.1f", potentialNewWeight)
				}
			}

			addButton.enabled = true
			addButton.alpha = 10.0
		}
	}

	@IBAction func add(_ sender: Any?) {

		weightEditChanged(sender)

		if let text = newValue.text {

			if text.doubleValue < 10 {
				return
			}

			last.text = "updating..."
			bmi.text = "  "
			info.text = "  "

			let date = NSDate.date
			let weight = HKQuantity.quantityWithUnit(DataAccess.weightUnit, doubleValue: text.stringByReplacingOccurrencesOfString(",", withString:".").doubleValue)
			let sample = HKQuantitySample.quantitySampleWithType(DataAccess.weightQuantityType, quantity: weight, startDate: date, endDate: date, metadata: NSMutableDictionary())

			self.newValue.text = ""
			weightEditChanged(sender)

			getHeight() { height in
				let weightInKg = weight.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
				let heightInM = height.quantity.doubleValueForUnit(HKUnit.meterUnit)
				let bmi = self.calculateBMIFrom(weight: weightInKg, height: heightInM)

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
					//dispatch_async(dispatch_get_main_queue()) {
					//performSegueWithIdentifier("ShowDetails", sender: nil) //TESTCASE for 69436: Silver CC: CC shows wrong multipart method names
					//}
					self.getBMI()
				}

			})
		}
	}

	@IBAction func showDetails(_ sender: Any?) {
		performSegueWithIdentifier("ShowDetails", sender: nil)
	}

	@IBAction func showActions(_ sender: Any?) {
		let actionSheet = UIAlertController(title: "Actions", message: nil, preferredStyle: .ActionSheet)

		//actionSheet.tintColor = UIApplication.sharedApplication?.delegate?.window?.tintColor
		actionSheet.addAction(UIAlertAction(title: "Export", style: .Default, handler: {
			self.exportAllData()
		}))
		actionSheet.addAction(UIAlertAction(title: "Import", style: .Default, handler: {
			self.importData()
		}))
		actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {
			actionSheet.dismissViewControllerAnimated(true, completion: nil)
		}))

		actionSheet.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
		presentViewController(actionSheet, animated: true, completion: {})
	}

	//
	//
	//

	func importData() {

	}

	func exportAllData() {
		var canceled = false
		let alert1 = UIAlertController(title: "Gathering Data", message: "Please Wait...", preferredStyle: .alert)
		alert1.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {
			canceled = true
			alert1.dismissAnimated(true) {}
		}))
		present(alert1, animated: true) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
				DataAccess.sharedInstance.getData() { json, error in
					if !canceled {
						DispatchQueue.main.async() {
							alert1.dismissAnimated(true) {
								if let json = json {
									let alert2 = UIAlertController(title: "Done", message: "\(json.Count) records found.", preferredStyle: .alert)
									alert2.addAction(UIAlertAction(title: "Copy", style: .Default, handler: {
										UIPasteboard.generalPasteboard.string = json.ToString()
										alert2.dismissAnimated(true) {}
									}))
									alert2.addAction(UIAlertAction(title: "Cacel", style: .Cancel, handler: {
										alert2.dismissAnimated(true) {}
									}))
									self.present(alert2, animated: true) {}
								} else if let error = error {
									NSLog("error %@", error)
									let alert2 = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
									alert2.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: {
										alert2.dismissAnimated(true) {}
									}))
									self.present(alert2, animated: true) {}
								}
							}
						}
					}
				}
			}
		}
	}

	//func exportAllData2() {
		//var canceled = false
		//let alert1 = UIAlertController(title: "Gathering Data", message: "Please Wait", preferredStyle: .alert)
		//alert1.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {
			//canceled = true
			//alert1.dismissAnimated(true) {}
		//}))
		//__await present(alert1, animated: true)

		//__await dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0))
		//let json = (__await DataAccess.sharedInstance.getData())
		//if !canceled {
			//__await DispatchQueue.main.async()
			//__await alert1.dismissAnimated(true)

			//let alert2 = UIAlertController(title: "Done", message: "Data has been copied to the pasteboard", preferredStyle: .alert)
			//alert2.addAction(UIAlertAction(title: "Copy", style: .Cancel, handler: {
				//UIPasteboard.generalPasteboard.setValue(json.ToString(), forPasteboardType: UIPasteboardTypeAutomatic)

				//alert2.dismissAnimated(true) {}
			//}))
			//alert2.addAction(UIAlertAction(title: "Done", style: .Cancel, handler: {
				//canceled = true
				//alert2.dismissAnimated(true) {}
			//}))
			//self.present(alert2, animated: true) {}
		//}
	//}
}