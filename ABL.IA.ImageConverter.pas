unit ABL.IA.ImageConverter;

interface

uses
  ABL.Core.DirectThread, ABL.VS.VSTypes, ABL.Core.BaseQueue, Windows;

type
  TImageConverter=class(TDirectThread)
  private
    FResultType: TABLImageType;
    FUseGreen: boolean;
    FThreshold: byte;
    function BGR2Bit(ImageFrom: PDecodedFrame): PDecodedFrame;
    function BGR2Gray(ImageFrom: PDecodedFrame): PDecodedFrame;
    function Bit2BGR(ImageFrom: PDecodedFrame): PDecodedFrame;
    function Bit2Gray(ImageFrom: PDecodedFrame): PDecodedFrame;
    function Gray2BGR(ImageFrom: PDecodedFrame): PDecodedFrame;
    function Gray2Bit(ImageFrom: PDecodedFrame): PDecodedFrame;
    function GetResultType: TABLImageType;
    function GetThreshold: byte;
    function GetUseGreen: boolean;
    procedure SetResultType(const Value: TABLImageType);
    procedure SetThreshold(const Value: byte);
    procedure SetUseGreen(const Value: boolean);
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    property ResultType: TABLImageType read GetResultType write SetResultType;
    property Threshold: byte read GetThreshold write SetThreshold;
    property UseGreen: boolean read GetUseGreen write SetUseGreen;
  end;

implementation

{ TImageConverter }

function TImageConverter.BGR2Bit(ImageFrom: PDecodedFrame): PDecodedFrame;
var
  RGBTriple: PRGBTriple;
  tmpSize,i: integer;
  tmpUseGreen: boolean;
  tmpThreshold,CurValue: byte;
  CurrentBit: SmallInt;
  BW: PByte;
begin
  RGBTriple:=PRGBTriple(ImageFrom.Data);
  tmpSize:=ImageFrom.Width*ImageFrom.Height;
  tmpSize:=tmpSize div 8+1;
  new(result);
  result.Width:=ImageFrom.Width;
  result.Height:=ImageFrom.Height;
  result.Left:=ImageFrom.Left;
  result.Top:=ImageFrom.Top;
  result.Time:=ImageFrom.Time;
  result.ImageType:=itBit;
  GetMem(result.Data,tmpSize);
  FLock.Enter;
  tmpUseGreen=FUseGreen;
  tmpThreshold=FThreshold;
  FLock.Leave;
  BW:=result.Data;
  BW^:=0;
  if tmpUseGreen then
    for i:=0 to ImageFrom.Width*ImageFrom.Height-1 do
    begin
      CurValue:=RGBTriple.rgbtGreen;
      CurrentBit:=i mod 8;
      if CurValue>tmpThreshold then
        BW^:=(BW^ or (1 shl CurrentBit));
      if CurrentBit=7 then
      begin
        Inc(BW);
        BW^:=0;
      end;
      Inc(RGBTriple);
    end
  else
    for i:=0 to ImageFrom.Width*ImageFrom.Height-1 do
    begin
      CurValue=RGBTriple.rgbtRed*0.299+RGBTriple.rgbtGreen*0.587+RGBTriple.rgbtBlue*0.114;
      CurrentBit:=i mod 8;
      if CurValue>tmpThreshold then
        BW^:=(BW^ or (1 shl CurrentBit));
      if CurrentBit=7 then
      begin
        Inc(BW);
        BW^:=0;
      end;
      Inc(RGBTriple);
    end;
end;

function TImageConverter.BGR2Gray(ImageFrom: PDecodedFrame): PDecodedFrame;
var
  RGBTriple: PRGBTriple;
  tmpSize,i: integer;
  tmpUseGreen: boolean;
  tmpThreshold,CurValue: byte;
  CurrentBit: SmallInt;
  BW: PByte;
begin
  RGBTriple:=PRGBTriple(ImageFrom.Data);
  tmpSize:=ImageFrom.Width*ImageFrom.Height;
  new(result);
  result.Width:=ImageFrom.Width;
  result.Height:=ImageFrom.Height;
  result.Left:=ImageFrom.Left;
  result.Top:=ImageFrom.Top;
  result.Time:=ImageFrom.Time;
  result.ImageType:=itGray;
  GetMem(result.Data,tmpSize);
  FLock.Enter;
  tmpUseGreen=FUseGreen;
  FLock.Leave;
  BW=result.Data;
  if tmpUseGreen then
    for i:=0 to ImageFrom.Width*ImageFrom.Height-1 do
    begin
      BW^:=RGBTriple.rgbtGreen;
      Inc(BW);
      Inc(RGBTriple);
    end
  else
    for i:=0 to ImageFrom.Width*ImageFrom.Height-1 do
    begin
      BW^:=RGBTriple.rgbtRed*0.299+RGBTriple.rgbtGreen*0.587+RGBTriple.rgbtBlue*0.114;
      Inc(BW);
      Inc(RGBTriple);
    end;
end;

function TImageConverter.Bit2BGR(ImageFrom: PDecodedFrame): PDecodedFrame;
var
  RGBTriple: PRGBTriple;
  tmpSize,i: integer;
  tmpUseGreen: boolean;
  tmpThreshold,CurValue: byte;
  CurrentBit: SmallInt;
  BW: PByte;
begin
  tmpSize=ImageFrom.Width*ImageFrom.Height*3;
  new(result);
  result.Width:=ImageFrom.Width;
  result.Height:=ImageFrom.Height;
  result.Left:=ImageFrom.Left;
  result.Top:=ImageFrom.Top;
  result.Time:=ImageFrom.Time;
  result.ImageType:=itBGR;
  GetMem(result.Data,tmpSize);
  BW:=ImageFrom.Data;
  RGBTriple=PRGBTriple(result.Data);
  for i:=0 to ImageFrom.Width*ImageFrom.Height-1 do
  begin
    CurrentBit:=i mod 8;
    if (BW and (1 shl CurrentBit))=(1 shl CurrentBit) then
      CurValue:=255
    else
      CurValue:=0;
    FillChar(RGBTriple^,3,CurValue);
    if CurrentBit=7 then
      Inc(BW);
    Inc(RGBTriple);
  end;
end;

function TImageConverter.Bit2Gray(ImageFrom: PDecodedFrame): PDecodedFrame;
var
  tmpSize,i: integer;
  tmpUseGreen: boolean;
  tmpThreshold,CurValue: byte;
  CurrentBit: SmallInt;
  BW,BT: PByte;
begin
  tmpSize=ImageFrom.Width*ImageFrom.Height;
  new(result);
  result.Width:=ImageFrom.Width;
  result.Height:=ImageFrom.Height;
  result.Left:=ImageFrom.Left;
  result.Top:=ImageFrom.Top;
  result.Time:=ImageFrom.Time;
  result.ImageType:=itGray;
  GetMem(result.Data,tmpSize);
  BW:=ImageFrom.Data;
  BT=PByte(result.Data);
  for i:=0 to ImageFrom.Width*ImageFrom.Height-1 do
  begin
    CurrentBit:=i mod 8;
    if (BW and (1 shl CurrentBit))=(1 shl CurrentBit) then
      CurValue:=255
    else
      CurValue:=0;
    BT^:=CurValue;
    if CurrentBit=7 then
      Inc(BW);
    Inc(BT);
  end;
end;

constructor TImageConverter.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  Start;
end;

procedure TImageConverter.DoExecute(var AInputData, AResultData: Pointer);
var
  DecodedInput,DecodedOutput: PDecodedFrame;
  tmpResultType: TABLImageType;
begin
  DecodedInput:=PDecodedFrame(AInputData);
  try
    FLock.Enter;
    tmpResultType:=FResultType;
    FLock.Leave;
    case DecodedInput.ImageType of
      itBGR:
        if tmpResultType=itBit then
          AResultData:=BGR2Bit(DecodedInput)
        else if tmpResultType=itGray then
          AResultData:=BGR2Gray(DecodedInput);
      itBit:
        if tmpResultType=itBGR then
          AResultData=Bit2BGR(DecodedInput)
        else if tmpResultType=itGray then
          AResultData=Bit2Gray(DecodedInput);
      itGray:
        if tmpResultType=itBit then
          AResultData=Gray2Bit(DecodedInput)
        else if tmpResultType=itBGR then
          AResultData=Gray2BGR(DecodedInput);
    end;
  finally
    FreeMem(DecodedInput.Data);
  end;
end;

function TImageConverter.GetResultType: TABLImageType;
begin
  FLock.Enter;
  Result:=FResultType;
  FLock.Leave;
end;

function TImageConverter.GetThreshold: byte;
begin
  FLock.Enter;
  Result:=FThreshold;
  FLock.Leave;
end;

function TImageConverter.GetUseGreen: boolean;
begin
  FLock.Enter;
  Result:=FUseGreen;
  FLock.Leave;
end;

function TImageConverter.Gray2BGR(ImageFrom: PDecodedFrame): PDecodedFrame;
var
  RGBTriple: PRGBTriple;
  tmpSize,i: integer;
  tmpUseGreen: boolean;
  tmpThreshold,CurValue: byte;
  CurrentBit: SmallInt;
  BW: PByte;
begin
  tmpSize=ImageFrom.Width*ImageFrom.Height*3;
  new(result);
  result.Width:=ImageFrom.Width;
  result.Height:=ImageFrom.Height;
  result.Left:=ImageFrom.Left;
  result.Top:=ImageFrom.Top;
  result.Time:=ImageFrom.Time;
  result.ImageType:=itBGR;
  GetMem(result.Data,tmpSize);
  BW:=ImageFrom.Data;
  RGBTriple=PRGBTriple(result.Data);
  for i:=0 to ImageFrom.Width*ImageFrom.Height-1 do
  begin
    FillChar(RGBTriple^,3,BW^);
    Inc(BW);
    Inc(RGBTriple);
  end;
end;

function TImageConverter.Gray2Bit(ImageFrom: PDecodedFrame): PDecodedFrame;
var
  RGBTriple: PRGBTriple;
  tmpSize,i: integer;
  tmpUseGreen: boolean;
  tmpThreshold,CurValue: byte;
  CurrentBit: SmallInt;
  BW,BT: PByte;
begin
  tmpSize:=ImageFrom.Width*ImageFrom.Height;
  tmpSize:=tmpSize div 8+1;
  new(result);
  result.Width:=ImageFrom.Width;
  result.Height:=ImageFrom.Height;
  result.Left:=ImageFrom.Left;
  result.Top:=ImageFrom.Top;
  result.Time:=ImageFrom.Time;
  result.ImageType:=itBit;
  GetMem(result.Data,tmpSize);
  FLock.Enter;
  tmpThreshold=FThreshold;
  FLock.Leave;
  BT:=result.Data;
  BT^:=0;
  BW:=ImageFrom.Data;
  for i:=0 to ImageFrom.Width*ImageFrom.Height-1 do
  begin
    CurrentBit:=i mod 8;
    if BW^>tmpThreshold then
      BT^:=(BT^ or (1 shl CurrentBit));
    if CurrentBit=7 then
    begin
      Inc(BT);
      BT^:=0;
    end;
    Inc(BW);
  end
end;

procedure TImageConverter.SetResultType(const Value: TABLImageType);
begin
  FLock.Enter;
  FResultType:=Value;
  FLock.Leave;
end;

procedure TImageConverter.SetThreshold(const Value: byte);
begin
  FLock.Enter;
  FThreshold:=Value;
  FLock.Leave;
end;

procedure TImageConverter.SetUseGreen(const Value: boolean);
begin
  FLock.Enter;
  FUseGreen:=Value;
  FLock.Leave;
end;

end.
