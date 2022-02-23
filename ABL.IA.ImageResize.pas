unit ABL.IA.ImageResize;

interface

uses
  ABL.Core.DirectThread, ABL.VS.VSTypes, Types, SyncObjs, ABL.Core.BaseQueue;

type
  TImageResize=class(TDirectThread)
  private
    FWidth, FHeight: word;
    function GetHeight: word;
    function GetWidth: word;
    procedure SetHeight(const Value: word);
    procedure SetWidth(const Value: word);
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    procedure SetSize(AWidth, AHeight: word);
    property Height: word read GetHeight write SetHeight;
    property Width: word read GetWidth write SetWidth;
  end;

implementation

{ TImageResize }

constructor TImageResize.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  Active:=true;
end;

procedure TImageResize.DoExecute(var AInputData, AResultData: Pointer);
var
  DecodedFrame, OutputFrame: PDecodedFrame;
  tmpWidth, tmpHeight: word;
  wh,hh: Extended;
  OffsetTo,OffsetFrom,x,y: integer;
begin
  DecodedFrame:=PDecodedFrame(AInputData);
  try
    FLock.Enter;
    tmpWidth:=FWidth;
    tmpHeight:=FHeight;
    FLock.Leave;
    wh:=DecodedFrame.Width/tmpWidth;
    hh:=DecodedFrame.Height/tmpHeight;
    OffsetTo:=0;
    OffsetFrom:=0;
    if (DecodedFrame.Width<tmpWidth) or (DecodedFrame.Height<tmpHeight) then //надо ли увеличивать картинку
    begin
      new(OutputFrame);
      OutputFrame.Height:=tmpHeight;
      OutputFrame.Width:=tmpWidth;
      OutputFrame.Time:=DecodedFrame.Time;
      GetMem(OutputFrame.Data,tmpWidth*tmpHeight*3);
      for y:=0 to tmpHeight-1 do
        for x:=0 to tmpWidth-1 do
        begin
          OffsetFrom:=(round(y*hh)*DecodedFrame.Width+round(x*wh))*3;
          Move(PByte(NativeUInt(DecodedFrame.Data)+OffsetFrom)^,PByte(NativeUInt(OutputFrame.Data)+OffsetTo)^,3);
          OffsetTo:=OffsetTo+3;
        end;
        AResultData:=OutputFrame;
    end
    else
    begin
      if (DecodedFrame.Width>tmpWidth) or (DecodedFrame.Height>tmpHeight) then //надо ли уменьшать картинку
      begin
        for y:=0 to tmpHeight-1 do
          for x:=0 to tmpWidth-1 do
          begin
            OffsetFrom:=(round(y*hh)*DecodedFrame.Width+round(x*wh))*3;
            Move(PByte(NativeUInt(DecodedFrame.Data)+OffsetFrom)^,PByte(NativeUInt(DecodedFrame.Data)+OffsetTo)^,3);
            OffsetTo:=OffsetTo+3;
          end;
        DecodedFrame.Width:=tmpWidth;
        DecodedFrame.Height:=tmpHeight;
      end;
      AResultData:=AInputData;
      AInputData:=nil;
    end;
  finally
    if assigned(AInputData) then
      FreeMem(DecodedFrame.Data);
  end;
end;

function TImageResize.GetHeight: word;
begin
  FLock.Enter;
  try
    result:=FHeight;
  finally
    FLock.Leave;
  end;
end;

function TImageResize.GetWidth: word;
begin
  FLock.Enter;
  try
    result:=FWidth;
  finally
    FLock.Leave;
  end;
end;

procedure TImageResize.SetHeight(const Value: word);
begin
  FLock.Enter;
  try
    FHeight:=Value;
  finally
    FLock.Leave;
  end;
end;

procedure TImageResize.SetSize(AWidth, AHeight: word);
begin
  FLock.Enter;
  try
    FHeight:=AHeight;
    FWidth:=AWidth;
  finally
    FLock.Leave;
  end;
end;

procedure TImageResize.SetWidth(const Value: word);
begin
  FLock.Enter;
  try
    FWidth:=Value;
  finally
    FLock.Leave;
  end;
end;

end.
