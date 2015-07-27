import UIKit
import HealthKit

@IBObject public class GraphView : UIView {

	public override func drawRect(rect: CGRect) {
		
		let font = UIFont.systemFontOfSize(10)
		
		var grayAttributes  = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.grayColor]
		if mornings != nil && evenings != nil {

			var blueAttributes  = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.blueColor]
			var redAttributes   = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.redColor]
			var greenAttributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.greenColor]

			let minY = yOffsetForValue(realMin)
			let minBezierPath = UIBezierPath()
			minBezierPath.moveToPoint(CGPointMake(startX, minY))
			minBezierPath.addLineToPoint(CGPointMake(endX, minY))
			UIColor.lightGrayColor.colorWithAlphaComponent(0.25).setStroke()
			minBezierPath.stroke()

			let minText = NSString.stringWithFormat("%0.1f%@", realMin, DataAccess.weightUnit.unitString)
			UIColor.grayColor.`set`()
			//let minSize = minText.sizeWithAttributes(grayAttributes)
			minText.drawAtPoint(CGPointMake(startX, minY+1), withAttributes: grayAttributes)
			
			if (realMax > realMin+0.1) {
				let maxY = yOffsetForValue(realMax)
				let maxBezierPath = UIBezierPath()
				maxBezierPath.moveToPoint(CGPointMake(startX, maxY))
				maxBezierPath.addLineToPoint(CGPointMake(endX, maxY))
				UIColor.lightGrayColor.colorWithAlphaComponent(0.25).setStroke()
				maxBezierPath.stroke()
	
				let maxText = NSString.stringWithFormat("%0.1f%@", realMax, DataAccess.weightUnit.unitString)
				let maxSize = maxText.sizeWithAttributes(grayAttributes)
				maxText.drawAtPoint(CGPointMake(endX-maxSize.width, maxY-maxSize.height-1), withAttributes: grayAttributes)
			}

			if lowest != nil {
				drawGraphFor(lowest, withColor: UIColor.greenColor)
			}
			drawGraphFor(mornings, withColor: UIColor.redColor)//.colorWithAlphaComponent(0.5))
			drawGraphFor(evenings, withColor: UIColor.blueColor)
			
			if lowest != nil {
				var morningString = diffStringBetweenOldValue(mornings[1], newValue: mornings[0])
				var eveningString = diffStringBetweenOldValue(evenings[1], newValue: evenings[0])

				if length(morningString) > 0 {
					morningString += " "
				}
								
				var totalString = morningString
				totalString += eveningString
				
				NSLog("morningString %@", morningString)
				NSLog("eveningString %@", eveningString)
				NSLog("totalString %@", totalString)
				
				if length(totalString) > 0 {
				 
					let totalSize = totalString.sizeWithAttributes(grayAttributes)
					var leftX = (frame.size.width-totalSize.width)/2
						
					if morningString != nil {
						let leftSize = morningString.sizeWithAttributes(redAttributes)
						morningString.drawAtPoint(CGPointMake(leftX, minY+1), withAttributes: redAttributes)
						leftX += leftSize.width
					}   
					if eveningString != nil {
						eveningString.drawAtPoint(CGPointMake(leftX, minY+1),withAttributes: blueAttributes)
					}   
				}
				
			}
			
			//
			// legend
			//
			var left = startX;
			var s = "first"
			var size = s.sizeWithAttributes(redAttributes)
			s.drawAtPoint(CGPointMake(left, startY), withAttributes: redAttributes)
			left += size.width;
	
			s = " / "
			size = s.sizeWithAttributes(grayAttributes)
			s.drawAtPoint(CGPointMake(left, startY), withAttributes: grayAttributes)
			left += size.width;
	
			s = "last"
			size = s.sizeWithAttributes(blueAttributes)
			s.drawAtPoint(CGPointMake(left, startY), withAttributes: blueAttributes)
			left += size.width;
	
			if lowest != nil {
				s = " / "
				size = s.sizeWithAttributes(grayAttributes)
				s.drawAtPoint(CGPointMake(left, startY), withAttributes: grayAttributes)
				left += size.width;
		
				s = "lowest"
				size = s.sizeWithAttributes(greenAttributes)
				s.drawAtPoint(CGPointMake(left, startY), withAttributes: greenAttributes)
			}
		} else {
			let text = "waiting for data from HealthKit"
			let size1 = text.sizeWithAttributes(grayAttributes);
			let point = CGPointMake( (frame.size.width-size1.width)/2, (frame.size.height-size1.height)/2 )
			text.drawAtPoint(point, withAttributes: grayAttributes);
		}
		/*let size1 = "first ".sizeWithFont(UIFont.systemFontOfSize(10));
		"first ".drawAtPoint(CGPointMake(startX, startY), withFont:font);
		let size2 = "last ".sizeWithFont(UIFont.systemFontOfSize(10))
		"last ".drawAtPoint(CGPointMake(startX+size1.width, startY), withFont:font)
		let size3 = "last ".sizeWithFont(UIFont.systemFontOfSize(10))
		"last ".drawAtPoint(CGPointMake(startX+size1.width+size.width, startY), withFont:font)*/
	}
	
	func diffStringBetweenOldValue(_ oldValue: id, newValue: id) -> String! { //TODO: drop _
		
		if (newValue != NSNull.null && oldValue != NSNull.null) {
		 
			let m0 = (newValue.quantity.doubleValueForUnit(DataAccess.weightUnit)*10).intValue
			let m1 = (oldValue.quantity.doubleValueForUnit(DataAccess.weightUnit)*10).intValue
			//NSLog("m0 %d, m1 %d", m0, m1)
			if m0 < m1 {
				return NSString.stringWithFormat("\u2212%.1f", (m1-m0).doubleValue/10) // 71383: Silver: Cant use unicode literal with {}
			} else if m0 > m1 {
				return NSString.stringWithFormat("+%.1f", (m0-m1).doubleValue/10)
			} else {
				return "±0"
			}
		}
		return nil
	}
	
	func pointForSample(_ s: HKQuantitySample, atIndex i: Int) -> CGPoint{ //TODO: drop _
		var y = yOffsetForValue(s.quantity.doubleValueForUnit(DataAccess.weightUnit))
		var x = endX - i*offsetX
		
		return CGPointMake(x,y)	
	}
	
	func yOffsetForValue(v: CGFloat) -> CGFloat {
		var  y = v
		y -= min
		y = sizeY - y / (max-min) * sizeY
		y += FRAME_SIZE
		return y
		
	}
	
	private func drawGraphFor(_ values: NSArray, withColor color: UIColor) { //TODO: drop _
		//var lastPoint: CGPoint = CGPointMake(0.0, 0.0)
		UIColor.whiteColor.setFill()
		color.setStroke()
		
		var i = 0
		var first= true
		let bezierPath = UIBezierPath()
		for i = 0; i < values.count; i++ {
			var s = values[i]
			if s is HKQuantitySample {

				let point = pointForSample(s, atIndex: i)
				if first {
					bezierPath.moveToPoint(point)
					first = false
				}
				else {

					/*(var centerPoint = CGPointMake((lastPoint.x+point.x)/2, (lastPoint.y+point.y)/2)

					if i+1 < values.count {
						let nextPoint = pointForSample(s, atIndex: i)

						if lastPoint.y < point.y && nextPoint.y > point.y {
							centerPoint = CGPointMake(centerPoint.x, centerPoint.y+(ABS(point.y-centerPoint.y)))
						} else {
							centerPoint = CGPointMake(centerPoint.x, centerPoint.y+(ABS(point.y-centerPoint.y)))
						//} else if lastPoint.y > point.y {
						//	centerPoint = CGPointMake(centerPoint.x, centerPoint.y-(ABS(point.y-centerPoint.y)))
						// }
						}

					}
					else
					{
						// See if your curve is decreasing or increasing
						// You can optimize it further by finding point on normal of line passing through midpoint
			
						if lastPoint.y < point.y {
							centerPoint = CGPointMake(centerPoint.x, centerPoint.y+(ABS(point.y-centerPoint.y)))
						} else if lastPoint.y > point.y {
							centerPoint = CGPointMake(centerPoint.x, centerPoint.y-(ABS(point.y-centerPoint.y)))
						}
					}
					bezierPath.addQuadCurveToPoint(point, controlPoint: centerPoint)*/
			
					bezierPath.addLineToPoint(point)
				}
				//lastPoint = point
			}
		}
		bezierPath.stroke()
		
		i = 0
		for s in values {
			if s is HKQuantitySample {
				let point = pointForSample(s, atIndex: i)
				let ovalPath = UIBezierPath.bezierPathWithOvalInRect(CGRectMake(point.x-CIRCLE_SIZE, point.y-CIRCLE_SIZE, CIRCLE_SIZE*2, CIRCLE_SIZE*2)) // silver bug!
				ovalPath.fill()
				ovalPath.stroke()
				//lastPoint = point
			}
			i++
		}
	}
	
	var mornings: NSArray!
	var evenings: NSArray!
	var lowest: NSArray!

	private var startX: CGFloat = 0
	private var startY: CGFloat = 0
	private var offsetX: CGFloat = 0
	private var endY: CGFloat = 0
	private var endX: CGFloat = 0
	
	let FRAME_SIZE = 20
	let CIRCLE_SIZE = 2.5

	private var min: CGFloat = 0
	private var max: CGFloat = 0
	private var realMin: CGFloat = 0
	private var realMax: CGFloat = 0
	private var sizeX: CGFloat = 0
	private var sizeY: CGFloat = 0
	
	public func dataChanged() {
		if mornings?.count > 0 {
			startX = FRAME_SIZE
			startY = FRAME_SIZE
			endY = frame.size.height-FRAME_SIZE
			endX = frame.size.width-FRAME_SIZE
			offsetX = (frame.size.width-FRAME_SIZE*2) / (mornings.count-1)

			sizeX = frame.size.width-FRAME_SIZE*2
			sizeY = frame.size.height-FRAME_SIZE*2
			
			min = 10_000.0
			max = 0.0
			for s in mornings {
				if s is HKQuantitySample {
					let q = s.quantity.doubleValueForUnit(DataAccess.weightUnit)
					max = MAX(max, q)
					min = MIN(min, q)
				}
			}
			for s in evenings {
				if s is HKQuantitySample {
					let q = s.quantity.doubleValueForUnit(DataAccess.weightUnit)
					max = MAX(max, q)
					min = MIN(min, q)
				}
			}
			realMin = min
			realMax = max
			if max == min {
				max = min+0.5
				min = min-0.5;
			}
			else if max < min+5
			{
				max = max+2.5;
				min = min-2.5;
			}
			else
			{
				let diff = max-min
				max = max+diff/1.75
				min = min-diff/1.75
			}
		}
		setNeedsDisplay()
	}
}
