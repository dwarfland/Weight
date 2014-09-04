import UIKit
import HealthKit

@IBObject public class GraphView : UIView {

	public override func drawRect(rect: CGRect) {
		
		if mornings != nil && evenings != nil {
			drawGraphFor(mornings, withColor: UIColor.redColor.colorWithAlphaComponent(0.5))
			drawGraphFor(evenings, withColor: UIColor.redColor)
			
			let font = UIFont.systemFontOfSize(10);
			let minText = NSString.stringWithFormat("%0.1f%@", min, "kg");
			UIColor.grayColor.`set`();
			let minSize = minText.sizeWithFont(font);
			minText.drawAtPoint(CGPointMake(startX, endY/*-minSize.height*/), withFont:font);

			let maxText = NSString.stringWithFormat("%0.1f%@", max, "kg");
			let maxSize = maxText.sizeWithFont(UIFont.systemFontOfSize(10));
			maxText.drawAtPoint(CGPointMake(endX-maxSize.width, startY), withFont:font);
		}
	}
	
	func pointForSample(s: HKQuantitySample, atIndex i: Int) -> CGPoint{
		
		var  y = s.quantity.doubleValueForUnit(MainViewController.weightUnit)
		y -= min
		y = sizeY - y / (max-min) * sizeY
		y += FRAME_SIZE
		
		var x = endX - i*offsetX
		
		return CGPointMake(x,y)
	
	}
	
	private func drawGraphFor(values: NSArray, withColor color: UIColor) {
		var lastPoint: CGPoint
		UIColor.whiteColor.setFill()
		color.setStroke()
		
		var i = 0
		let bezierPath = UIBezierPath()
		for i = 0; i < values.count; i++ {
			var s = values[i];
			if s is HKQuantitySample {

				let point = pointForSample(s, atIndex: i)
				if i == 0 {
					bezierPath.moveToPoint(point)
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
		
		i = 0;
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

	private var startX: CGFloat
	private var startY: CGFloat
	private var offsetX: CGFloat
	private var endY: CGFloat
	private var endX: CGFloat
	
	let FRAME_SIZE = 20
	let CIRCLE_SIZE = 2.5

	private var min: CGFloat
	private var max: CGFloat
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
		}
		setNeedsDisplay()
	}
}
