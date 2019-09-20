namespace TwinPeaks;

interface

uses
  UIKit;

type
  TPBaseCellView = public class(UIView)
  private
    fHighlighted: Boolean;
    method isHighlighted: Boolean;
    method setHighlighted(aValue: Boolean);
  protected
  public
    class method createGradientImageWidth(pixelsWide: CGFloat) height(pixelsHigh: CGFloat) fromColor(fromColor: UIColor) toColor(toColor: UIColor): UIImage;
    method createGradientImage: UIImage;
    method createGradientImageWidth(pixelsWide: CGFloat) height(pixelsHigh: CGFloat): UIImage;

    property gradientStartColor: UIColor := UIColor.colorWithRed(0.9) green(0.9) blue(0.9) alpha(1.0);
    property gradientStopColor:  UIColor := UIColor.colorWithRed(1.0) green(1.0) blue(1.0) alpha(1.0);

    property cell: weak UITableViewCell;

    method initWithFrame(frame: CGRect): InstanceType; override;
    property highlighted: Boolean read isHighlighted write setHighlighted;
  end;

implementation

method TPBaseCellView.initWithFrame(frame: CGRect): id;
begin
  self := inherited initWithFrame(frame);
  if assigned(self) then begin
    opaque := NO;
    backgroundColor := UIColor.clearColor;
  end;
  result := self;
end;

class method TPBaseCellView.createGradientImageWidth(pixelsWide: CGFloat) height(pixelsHigh: CGFloat) fromColor(fromColor: UIColor) toColor(toColor: UIColor): UIImage;
begin
  var theCGImage: CGImageRef := nil;
  var colorSpace := CGColorSpaceCreateDeviceRGB();

  var gradientBitmapContext := CGBitmapContextCreate(nil, Integer(pixelsWide), Integer(pixelsHigh),
                                                               8, 0, colorSpace, CGBitmapInfo(CGImageAlphaInfo.kCGImageAlphaNoneSkipFirst));

    // define the start and end grayscale values (with the alpha, even though
    // our bitmap context doesn't support alpha the gradient requires it)
  var startColor := fromColor.CGColor;
  var endColor := toColor.CGColor;
  var colors: array[0..1] of CGColorRef := [startColor, endColor];

  //CGFloat locations[2] = begin 0.0, 1.0 end;;

  var colorArray := CFArrayCreate (nil, ^^Void(@colors), 2, nil);
  // create the CGGradient and then release the gray color space
  var grayScaleGradient := CGGradientCreateWithColors(nil{colorSpace}, colorArray, nil{locations});
  CGColorSpaceRelease(colorSpace);
  CFRelease(colorArray);

  // create the start and end points for the gradient vector (straight down)
  var gradientStartPoint := CGPointZero;
  //var gradientEndPoint := CGPointMake(0, pixelsHigh);
  var gradientEndPoint: CGPoint;
  gradientEndPoint.x := 0;
  gradientEndPoint.y := pixelsHigh;

  // draw the gradient into the gray bitmap context
  CGContextDrawLinearGradient(gradientBitmapContext, grayScaleGradient, gradientStartPoint,
                              gradientEndPoint, CGGradientDrawingOptions.kCGGradientDrawsAfterEndLocation);
  CGGradientRelease(grayScaleGradient);

  // convert the context into a CGImageRef and release the context
  theCGImage := CGBitmapContextCreateImage(gradientBitmapContext);
  CGContextRelease(gradientBitmapContext);

  // return the imageref containing the gradient
  result := UIImage.imageWithCGImage(theCGImage);
  CGImageRelease(theCGImage);
end;

method TPBaseCellView.createGradientImageWidth(pixelsWide: CGFloat) height(pixelsHigh: CGFloat): UIImage;
begin
  result := createGradientImageWidth(pixelsWide) height(pixelsHigh) fromColor(gradientStartColor) toColor(gradientStopColor);
end;

method TPBaseCellView.createGradientImage: UIImage;
begin
  var f := bounds;
  result := createGradientImageWidth(f.size.width) height(f.size.height);
end;

method TPBaseCellView.isHighlighted: Boolean;
begin
  result := fHighlighted;
end;

method TPBaseCellView.setHighlighted(aValue: Boolean);
begin
  fHighlighted := aValue;
  setNeedsDisplay();
end;

end.