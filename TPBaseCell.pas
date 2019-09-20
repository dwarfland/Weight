namespace TwinPeaks;

interface

uses
  UIKit;

type
  &Class = id; // 59580: Nougat: Cant use "Class" type

  TPBaseCell = public class(UITableViewCell)
  private
    fView: UIView;
  protected
  public
    method initWithStyle(style: UITableViewCellStyle) reuseIdentifier(aReuseIdentifier: String): InstanceType; override;
    method initWithStyle(style: UITableViewCellStyle) view(aView: UIView): InstanceType;
    method initWithStyle(style: UITableViewCellStyle) viewClass(aClass: &Class): InstanceType;
    method initWithStyle(style: UITableViewCellStyle) viewClass(aClass: &Class) size(aSize: CGSize): InstanceType;

    method setBackgroundGradient;
    method setSelectedBackgroundGradientFromColor(fromColor: UIColor) toColor(toColor: UIColor);
    method setBackgroundGradientFromColor(fromColor: UIColor) toColor(toColor: UIColor);
    method setSelected(selected: Boolean) animated(animated: Boolean); override;

    property view: UIView read fView write fView;
  end;

implementation

method TPBaseCell.initWithStyle(style: UITableViewCellStyle) reuseIdentifier(aReuseIdentifier: String): InstanceType;
begin
  self := inherited initWithStyle(style) reuseIdentifier(aReuseIdentifier);
  if assigned(self) then begin
    //if UIDevice.currentDevice.systemVersion.floatValue < 7.0 then
    //  setBackgroundGradient();
  end;
  result := self;
end;

method TPBaseCell.initWithStyle(style: UITableViewCellStyle) view(aView: UIView): InstanceType;
begin
  self := inherited initWithStyle(style) reuseIdentifier(aView.class.description);
  if assigned(self) then begin
    fView := aView;
    //fView.setFrame := contentView.bounds;
    fView.frame := contentView.bounds;
    fView.autoresizingMask :=  UIViewAutoresizing.UIViewAutoresizingFlexibleWidth or UIViewAutoresizing.UIViewAutoresizingFlexibleHeight;
    contentView.addSubview(fView);
    //setBackgroundGradient();
    if fView.respondsToSelector(selector(setCell:)) then
      TPBaseCellView(fView).setCell(self);
  end;
  result := self;
end;

method TPBaseCell.initWithStyle(style: UITableViewCellStyle) viewClass(aClass: &Class): InstanceType;
begin
  self := initWithStyle(style) reuseIdentifier(aClass.description);
  if assigned(self) then begin
    //fView := aClass.alloc.initWithFrame(contentView.bounds) as UIView;
    fView := new WeightCellView withFrame(contentView.bounds);

    fView.autoresizingMask :=  UIViewAutoresizing.UIViewAutoresizingFlexibleWidth or UIViewAutoresizing.UIViewAutoresizingFlexibleHeight;
    contentView.addSubview(fView);
  end;
  result := self;
end;

method TPBaseCell.initWithStyle(style: UITableViewCellStyle) viewClass(aClass: &Class) size(aSize: CGSize): InstanceType;
begin
  //var aView := &aClass.alloc.initWithFrame(CGRectMake(0.0, 0.0, size.width, size.height));
  //self := initWithStyle(style) view(aView);
 // result := self;
end;

method TPBaseCell.setSelected(selected: Boolean) animated(animated : Boolean);
begin
  inherited setSelected(selected) animated(animated);
    // Configure the view for the selected state
end;

method TPBaseCell.setBackgroundGradientFromColor(fromColor: UIColor) toColor(toColor: UIColor);
begin
  var f := frame;
  var i := TPBaseCellView.createGradientImageWidth(f.size.width) height(f.size.height) fromColor(fromColor) toColor(toColor);
  var b := new UIImageView withImage(i);
  setBackgroundView(b);
end;

method TPBaseCell.setSelectedBackgroundGradientFromColor(fromColor: UIColor) toColor(toColor: UIColor);
begin
  var f := frame;
  var i := TPBaseCellView.createGradientImageWidth(f.size.width) height(f.size.height) fromColor(fromColor) toColor(toColor);
  var b := new UIImageView withImage(i);
  setSelectedBackgroundView(b);
end;

method TPBaseCell.setBackgroundGradient;
begin
  {if assigned(fView) and fView.respondsToSelector(selector(gradientStartColor)) and fView.respondsToSelector(selector(gradientStopColor)) then begin
    setBackgroundGradientFromColor(TPBaseCellView(fView).gradientStartColor) toColor(TPBaseCellView(fView).gradientStopColor);
  end
  else }begin
    var gradientStartColor := UIColor.colorWithRed(0.9) green(0.9) blue(0.9) alpha(1.0);
    var gradientStopColor := UIColor.colorWithRed(1.0) green(1.0) blue(1.0) alpha(1.0);
    setBackgroundGradientFromColor(gradientStartColor) toColor(gradientStopColor);
  end;
end;

end.