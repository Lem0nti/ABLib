unit ABL.IA.ImageCutter;

interface

uses
  ABL.Core.DirectThread, ABL.VS.VSTypes, Types, SyncObjs;

type
  TImageCutter=class(TDirectThread)
  private
    FCutRect: TRect;
    function GetCutRect: TRect;
    procedure SetCutRect(const Value: TRect);
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    property CutRect: TRect read GetCutRect write SetCutRect;
  end;

implementation

{ TImageCutter }

procedure TImageCutter.DoExecute(var AInputData, AResultData: Pointer);
var
  DecodedFrame: PDecodedFrame;
  AbsRect: TRect;
  y: integer;
begin
  DecodedFrame:=PDecodedFrame(AInputData);
  AResultData:=AInputData;
  AInputData:=nil;
  //превращаем относительный прямоугольник в конкретный, вверх ногами
  AbsRect:=Rect(Round(CutRect.Left/10000*DecodedFrame.Width),Round((CutRect.Top)/10000*DecodedFrame.Height),
      Round(CutRect.Right/10000*DecodedFrame.Width),Round((CutRect.Bottom)/10000*DecodedFrame.Height));
  while AbsRect.Width mod 4 > 0 do
    AbsRect.Width:=AbsRect.Width+1;
  for y := AbsRect.Top to AbsRect.Bottom do
    Move(PByte(NativeUInt(DecodedFrame.Data)+(y*DecodedFrame.Width+AbsRect.Left)*3)^,PByte(NativeUInt(DecodedFrame.Data)+((y-AbsRect.Top)*AbsRect.Width)*3)^,AbsRect.Width*3);
  DecodedFrame.Width:=AbsRect.Width;
  DecodedFrame.Height:=AbsRect.Height;
end;

function TImageCutter.GetCutRect: TRect;
begin
  FLock.Enter;
  try
    result:=FCutRect;
  finally
    FLock.Leave;
  end;
end;

procedure TImageCutter.SetCutRect(const Value: TRect);
begin
  FLock.Enter;
  try
    FCutRect:=Value;
  finally
    FLock.Leave;
  end;
end;

end.
