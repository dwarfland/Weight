import Foundation
import UIKit
import TwinPeaks
import HealthKit

@IBObject public class NumbersViewController : UITableViewController {

	public override func viewDidLoad() {
		title = "Numbers"

		updateData()
	}

	private var data: CollectedWeightData?

	private func updateData() {
		DataAccess.sharedInstance.getData(days: 1000) { (newData: CollectedWeightData?) in
			dispatch_async(dispatch_get_main_queue()) {
				self.data = newData
				self.tableView.reloadData()
			}
		}
	}

	func numberOfSectionsInTableView(_ tableView: UITableView!) -> NSInteger {
		return 1
	}

	func tableView(_ tableView: UITableView!, numberOfRowsInSection section: NSInteger) -> NSInteger {
		if let morningValues = data?.morningValues {
			return morningValues.count
		}
		return 0;
	}

	func tableView(_ tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell {

		let result = TPBaseCell(style: .UITableViewCellStyleSubtitle, viewClass: typeOf(WeightCellView))

		(result.view as! WeightCellView).first = indexPath.row == 0

		let dateComponents = NSDateComponents()
		dateComponents.setDay(-indexPath.row);
		(result.view as! WeightCellView).date = NSCalendar.currentCalendar.dateByAddingComponents(dateComponents, toDate: NSDate.date, options:0)

		if data?.morningValues[indexPath.row] != NSNull.null {
			(result.view as! WeightCellView).morningValue = data?.morningValues[indexPath.row]
		}
		if data?.eveningValues[indexPath.row] != NSNull.null {
			(result.view as! WeightCellView).eveningValue = data?.eveningValues[indexPath.row]
		}
		return result
	}
}

public class WeightCellView : TPBaseCellView {

	var first: Bool = false
	var lowest: Bool = false
	var morningValue: HKQuantitySample?
	var eveningValue: HKQuantitySample?
	var lowestValue: HKQuantitySample?
	var date: NSDate!

	init(frame: CGRect) {
		super.init(frame: frame)
	}

	public override func drawRect(_ rect: CGRect) {

		let mainFont = first ? UIFont.systemFontOfSize(26) : UIFont.fontWithName("HelveticaNeue-Light", size: 26)!
		let dataFont = first ? UIFont.boldSystemFontOfSize(26) : UIFont.systemFontOfSize(26)!
		let smallFont = UIFont.fontWithName("HelveticaNeue-Light",size: 13)!

		let mainAttributes = [NSFontAttributeName: mainFont, NSForegroundColorAttributeName: available("iOS 13.0") ? UIColor.labelColor : UIColor.blackColor]
		let morningAttributes = [NSFontAttributeName: mainFont, NSForegroundColorAttributeName: UIColor.colorNamed("Red")!.colorWithAlphaComponent(0.75)]
		let eveningAttributes = [NSFontAttributeName: dataFont, NSForegroundColorAttributeName: UIColor.colorNamed("Blue")!]
		let seperatorAttributes = [NSFontAttributeName: mainFont, NSForegroundColorAttributeName: UIColor.grayColor]
		let smallAttributes = [NSFontAttributeName: smallFont, NSForegroundColorAttributeName: UIColor.grayColor]

		var lCalendar = NSCalendar.currentCalendar
		var lUnitFlags = NSCalendarUnit.NSWeekdayCalendarUnit || NSCalendarUnit.NSYearCalendarUnit
		var lComponents = lCalendar.components(lUnitFlags, fromDate: date)
		var lThisYear = lCalendar.components(NSCalendarUnit.NSYearCalendarUnit, fromDate: date).year

		var lDiffComponents = lCalendar.components(NSCalendarUnit.NSDayCalendarUnit, fromDate: date, toDate: NSDate.date, options: 0)
		var lOverOneWeek = lDiffComponents.day > 7

		var lDayFormatter = NSDateFormatter()
		lDayFormatter.dateFormat = "EEEE"

		var lFarDateFormatter = NSDateFormatter()
		if lThisYear == lComponents.year {
			lFarDateFormatter.dateFormat = ", MMM dd"
		} else {
			lFarDateFormatter.dateFormat = ", MMM dd, yyyy"
		}

		var lDayString = "Today"
		if !first {
			lDayString = lDayFormatter.stringFromDate(date)
		}


		if lowest {
			UIColor.colorWithRed(1.0, green: 0.9, blue: 0.9, alpha: 1.0).setFill()
			UIRectFill(frame)
		} else {
			if #available(iOS 13.0) {
				UIColor.systemBackgroundColor.setFill()
			} else {
				UIColor.whiteColor.setFill()
			}
			UIRectFill(frame)
			/*(if AppDelegate.instance.best.intValue > 0 then begin
			  var f2 := f;
			  f2.size.width := steps.floatValue/AppDelegate.instance.best.floatValue * f.size.width;
			  UIColor.colorWithRed(0.97) green(0.97) blue(0.97) alpha(1.0).setFill;

			  UIRectFill(f2);
			}*/
		}

		let lDaySize = lDayString.sizeWithAttributes(mainAttributes)
		let lDayFrame = CGRectMake(5.0, 6.0, lDaySize.width, lDaySize.height)
		lDayString.drawInRect(lDayFrame, withAttributes: mainAttributes)

		if lOverOneWeek {
			let lDayString2 = lFarDateFormatter.stringFromDate(date);
			let lDaySize2 = lDayString2.sizeWithAttributes(smallAttributes);
			let lDayFrame2 = CGRectMake(lDayFrame.origin.x+lDayFrame.size.width-3, 18.0, lDaySize2.width, lDaySize2.height);
			lDayString2.drawInRect(lDayFrame2, withAttributes: smallAttributes);
		}

		if (eveningValue == nil && morningValue == nil) {
			return;
		}

		var mainValue: HKQuantitySample = eveningValue != nil ? eveningValue! : morningValue!

		if mainValue != nil {
			//self.("eveningValue?.quantity.doubleValueForUnit(DataAccess.weightUnit) %@", mainValue.quantity.doubleValueForUnit(DataAccess.weightUnit))
			let eveningString = NSString.stringWithFormat("%.1f", mainValue.quantity.doubleValueForUnit(DataAccess.weightUnit).doubleValue)
			let eveningSize = eveningString.sizeWithAttributes(eveningAttributes)
			let eveningFrame = CGRectMake(frame.size.width-5.0-eveningSize.width, 6.0, eveningSize.width, eveningSize.height)
			eveningString.drawInRect(eveningFrame, withAttributes: eveningAttributes)

			if (eveningValue != nil && morningValue != nil) {

				let eveningValue2 = eveningValue!
				let morningValue2 = morningValue!

				if (Int(trunc(eveningValue2.quantity.doubleValueForUnit(DataAccess.weightUnit)*10)) !=
					Int(trunc(morningValue2.quantity.doubleValueForUnit(DataAccess.weightUnit)*10))) {

					let seperatorString = "/"
					let seperatorSize = seperatorString.sizeWithAttributes(seperatorAttributes)
					let seperatorFrame = CGRectMake(eveningFrame.origin.x-seperatorSize.width, 6.0, seperatorSize.width, seperatorSize.height)
					seperatorString.drawInRect(seperatorFrame, withAttributes: seperatorAttributes)

					let morningString = NSString.stringWithFormat("%.1f", morningValue2.quantity.doubleValueForUnit(DataAccess.weightUnit).doubleValue)
					let morningSize = morningString.sizeWithAttributes(morningAttributes)
					let morningFrame = CGRectMake(seperatorFrame.origin.x-morningSize.width, 6.0, morningSize.width, morningSize.height)
					morningString.drawInRect(morningFrame, withAttributes: morningAttributes)
				}
			}
		}
	}
}