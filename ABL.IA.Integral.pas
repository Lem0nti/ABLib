unit ABL.IA.Ingtegral;

interface

uses
  ABL.Core.DirectThread, ABL.Core.BaseQueue, ABL.VS.VSTypes, ABL.IA.IATypes, SysUtils;

type
  TIngtegral=class(TDirectThread)
  private
    FUseGreen: boolean;
    function GetUseGreen: boolean;
    procedure SetUseGreen(const Value: boolean);
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    property UseGreen: boolean read GetUseGreen write SetUseGreen;
  end;

implementation

{ TIngtegral }

constructor TIngtegral.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  Start;
end;

procedure TIngtegral.DoExecute(var AInputData, AResultData: Pointer);
var
  Result: array of array of Cardinal;
  ImageDataHeader: PImageDataHeader;
  sz: Cardinal;
  tmpUseGreen: boolean;
  RGBLine: PRGBArray;
  x,y: integer;
  ByteArray: PByteArray;
begin
  ImageDataHeader:=AInputData;
  if ImageDataHeader.ImageType<itBGRIntegral then
  begin
    sz:=ImageDataHeader.Width*ImageDataHeader.Height*SizeOf(Cardinal)+SizeOf(TImageDataHeader);
    GetMem(AResultData,sz);
    FillChar(AResultData^,sz,255);
    move(AInputData^,AResultData^,SizeOf(TImageDataHeader));
    SetLength(Result,ImageDataHeader.Width,ImageDataHeader.Height);
    if ImageDataHeader.ImageType=itBGR then
    begin
      RGBLine:=ImageDataHeader.Data;
      FLock.Enter;
      tmpUseGreen:=FUseGreen;
      FLock.Leave;
      if tmpUseGreen then
      begin
        Result[0][0]:=RGBLine[0].rgbtGreen;
        for x := 1 to ImageDataHeader.Width-1 do
          Result[x][0]:=Result[x-1][0]+RGBLine[x].rgbtGreen;
        for y := 1 to ImageDataHeader.Height-1 do
        begin
          if Terminated then
            exit;
          RGBLine:=PRGBArray(PByte(NativeUInt(ImageDataHeader.Data)+y*ImageDataHeader.Width*3));
          for x := 0 to ImageDataHeader.Width-1 do
          begin
            Result[x][y]:=Result[x][y-1];
            if x>0 then
              Result[x][y]:=Result[x][y]+Result[x-1][y]-Result[x-1][y-1];
            Result[x][y]:=Result[x][y]+RGBLine[x].rgbtGreen;
          end;
        end;
      end
      else
      begin
        Result[0][0]:=RGBLine[0].Brightness;
        for x := 1 to ImageDataHeader.Width-1 do
          Result[x][0]:=Result[x-1][0]+RGBLine[x].Brightness;
        for y := 1 to ImageDataHeader.Height-1 do
        begin
          if Terminated then
            exit;
          RGBLine:=PRGBArray(PByte(NativeUInt(ImageDataHeader.Data)+y*ImageDataHeader.Width*3));
          for x := 0 to ImageDataHeader.Width-1 do
          begin
            Result[x][y]:=Result[x][y-1];
            if x>0 then
              Result[x][y]:=Result[x][y]+Result[x-1][y]-Result[x-1][y-1];
            Result[x][y]:=Result[x][y]+RGBLine[x].Brightness;
          end;
        end;
      end;
    end
    else if ImageDataHeader.ImageType=itGray then
    begin
      ByteArray:=ImageDataHeader.Data;
      Result[0][0]:=ByteArray[0];
      for x := 1 to ImageDataHeader.Width-1 do
        Result[x][0]:=Result[x-1][0]+ByteArray[x];
      for y := 1 to ImageDataHeader.Height-1 do
      begin
        if Terminated then
          exit;
        ByteArray:=PByteArray(PByte(NativeUInt(ImageDataHeader.Data)+y*ImageDataHeader.Width));
        for x := 0 to ImageDataHeader.Width-1 do
        begin
          Result[x][y]:=Result[x][y-1];
          if x>0 then
            Result[x][y]:=Result[x][y]+Result[x-1][y]-Result[x-1][y-1];
          Result[x][y]:=Result[x][y]+ByteArray[x];
        end;
      end;
    end;
    ImageDataHeader:=AResultData;
    ImageDataHeader.ImageType:=ImageDataHeader.ImageType+3;
    ImageDataHeader.TimedDataHeader.DataHeader.Size:=sz;
    Move(Result[0][0],ImageDataHeader.Data^,ImageDataHeader.Width*ImageDataHeader.Height*SizeOf(Cardinal));
  end;
end;

function TIngtegral.GetUseGreen: boolean;
begin
  FLock.Enter;
  try
    result:=FUseGreen;
  finally
    FLock.Leave;
  end;
end;

procedure TIngtegral.SetUseGreen(const Value: boolean);
begin
  FLock.Enter;
  try
    FUseGreen:=Value;
  finally
    FLock.Leave;
  end;
end;

end.
