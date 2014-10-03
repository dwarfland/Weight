import UIKit
import HealthKit

@IBObject public class GraphView : UIView {

	public override func drawRect(rect: CGRect) {
		
		let font = UIFont.systemFontOfSize(10)
		
		if mornings != nil && evenings != nil {


			let minY = yOffsetForValue(realMin)
			let minBezierPath = UIBezierPath()
			minBezierPath.moveToPoint(CGPointMake(startX, minY))
			minBezierPath.addLineToPoint(CGPointMake(endX, minY))
			UIColor.lightGrayColor.colorWithAlphaComponent(0.25).setStroke()
			minBezierPath.stroke()

			let minText = NSString.stringWithFormat("%0.1f%@", realMin, MainViewController.weightUnit.unitString)
			UIColor.grayColor.`set`()
			let minSize = minText.sizeWithFont(font)
			minText.drawAtPoint(CGPointMake(startX, minY+1), withFont:font)
			
			if (realMax > realMin+0.1) {
				let maxY = yOffsetForValue(realMax)
				let maxBezierPath = UIBezierPath()
				maxBezierPath.moveToPoint(CGPointMake(startX, maxY))
				maxBezierPath.addLineToPoint(CGPointMake(endX, maxY))
				UIColor.lightGrayColor.colorWithAlphaComponent(0.25).setStroke()
				maxBezierPath.stroke()
	
				let maxText = NSString.stringWithFormat("%0.1f%@", realMax, MainViewController.weightUnit.unitString)
				UIColor.grayColor.`set`()
				let maxSize = maxText.sizeWithFont(font)
				maxText.drawAtPoint(CGPointMake(endX-maxSize.width, maxY-maxSize.height-1), withFont:font)
			}

			if lowest != nil {
				drawGraphFor(lowest, withColor: UIColor.greenColor)
			}
			drawGraphFor(mornings, withColor: UIColor.redColor)//.colorWithAlphaComponent(0.5))
			drawGraphFor(evenings, withColor: UIColor.blueColor)
		}

		var left = startX;
		var s = "first"
		UIColor.redColor.`set`()
		var size = s.sizeWithFont(UIFont.systemFontOfSize(10));
		s.drawAtPoint(CGPointMake(left, startY), withFont:font);
		left += size.width;

		s = " / "
		UIColor.grayColor.`set`()
		size = s.sizeWithFont(UIFont.systemFontOfSize(10))
		s.drawAtPoint(CGPointMake(left, startY), withFont:font)
		left += size.width;

		s = "last"
		UIColor.blueColor.`set`()
		size = s.sizeWithFont(UIFont.systemFontOfSize(10))
		s.drawAtPoint(CGPointMake(left, startY), withFont:font)
		left += size.width;

		if lowest != nil {
			s = " / "
			UIColor.grayColor.`set`()
			size = s.sizeWithFont(UIFont.systemFontOfSize(10))
			s.drawAtPoint(CGPointMake(left, startY), withFont:font)
			left += size.width;
	
			s = "lowest"
			UIColor.greenColor.`set`()
			size = s.sizeWithFont(UIFont.systemFontOfSize(10))
			s.drawAtPoint(CGPointMake(left, startY), withFont:font)
		}
		/*let size1 = "first ".sizeWithFont(UIFont.systemFontOfSize(10));
		"first ".drawAtPoint(CGPointMake(startX, startY), withFont:font);
		let size2 = "last ".sizeWithFont(UIFont.systemFontOfSize(10))
		"last ".drawAtPoint(CGPointMake(startX+size1.width, startY), withFont:font)
		let size3 = "last ".sizeWithFont(UIFont.systemFontOfSize(10))
		"last ".drawAtPoint(CGPointMake(startX+size1.width+size.width, startY), withFont:font)*/
	}
	
	func pointForSample(s: HKQuantitySample, atIndex i: Int) -> CGPoint{
		var y = yOffsetForValue(s.quantity.doubleValueForUnit(MainViewController.weightUnit))
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
	
	private func drawGraphFor(values: NSArray, withColor color: UIColor) {
		var lastPoint: CGPoint
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
				lastPoint = point
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
				lastPoint = point
			}
			i++
		}
	}
	
	var mornings: NSArray!
	var evenings: NSArray!
	var lowest: NSArray!

	private var startX: CGFloat
	private var startY: CGFloat
	private var offsetX: CGFloat
	private var endY: CGFloat
	private var endX: CGFloat
	
	let FRAME_SIZE = 20
	let CIRCLE_SIZE = 2.5

	private var min: CGFloat
	private var max: CGFloat
	private var realMin: CGFloat
	private var realMax: CGFloat
	private var sizeX: CGFloat
	private var sizeY: CGFloat
	
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
					let q = s.quantity.doubleValueForUnit(MainViewController.weightUnit)
					max = MAX(max, q)
					min = MIN(min, q)
				}
			}
			for s in evenings {
				if s is HKQuantitySample {
					let q = s.quantity.doubleValueForUnit(MainViewController.weightUnit)
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
		}
		setNeedsDisplay()
	}
}
