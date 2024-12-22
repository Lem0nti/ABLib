unit ABL.IA.FindDark;

interface

uses
  ABL.Core.DirectThread, ABL.Core.BaseQueue, ABL.VS.VSTypes, ABL.IA.IATypes, SysUtils;

type
  TFindDark=class(TDirectThread)
  private
    tmpBuffer: Pointer;
    FGreenDec: Real;
    function GetGreenDec: Real;
    procedure SetGreenDec(const Value: Real);
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    destructor Destroy; override;
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
    property GreenDec: Real read GetGreenDec write SetGreenDec;
  end;

implementation

{ TFindDark }

constructor TFindDark.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  GetMem(tmpBuffer,2048*2048*3);
  FGreenDec:=0.8;
  Start;
end;

destructor TFindDark.Destroy;
begin
  FreeMem(tmpBuffer);
  inherited;
end;

procedure TFindDark.DoExecute(var AInputData: Pointer; var AResultData: Pointer);
var
  x,y,CurrentPixel,CurrentBit: integer;
  CurrentByte: Cardinal;
  DecodedFrame: PImageDataHeader;
  RGBLine,RGBLineTop,RGBLineBottom: PRGBArray;
  ByteLine,ByteLineTop,ByteLineBottom: PByteArray;
  ResultPointer: PByte;
  tmpDataSize: integer;
  CurGreen: byte;
  CurDec: Real;
begin
  DecodedFrame:=AInputData;
  if DecodedFrame.ImageType in [itBGR,itGray] then
  begin
    tmpDataSize:=((DecodedFrame.Width*DecodedFrame.Height) div 8)+1;
    FillChar(tmpBuffer^,tmpDataSize,255);
    FLock.Enter;
    CurDec:=FGreenDec;
    FLock.Enter;
    if DecodedFrame.ImageType=itBGR then
      for y:=1 to DecodedFrame.Height-2 do
      begin
        RGBLine:=PRGBArray(NativeUInt(DecodedFrame.Data)+y*DecodedFrame.Width*3);
        RGBLineTop:=PRGBArray(NativeUInt(DecodedFrame.Data)+(y-1)*DecodedFrame.Width*3);
        RGBLineBottom:=PRGBArray(NativeUInt(DecodedFrame.Data)+(y+1)*DecodedFrame.Width*3);
        for x:=1 to DecodedFrame.Width-2 do
        begin
          CurrentPixel:=y*DecodedFrame.Width+x;
          CurrentByte:=CurrentPixel div 8;
          CurrentBit:=CurrentPixel mod 8;
          CurGreen:=Round(RGBLine[x].rgbtGreen*CurDec);
          if RGBLineTop[x-1].rgbtGreen>CurGreen then
            if RGBLineTop[x].rgbtGreen>CurGreen then
              if RGBLineTop[x+1].rgbtGreen>CurGreen then
                if RGBLine[x-1].rgbtGreen>CurGreen then
                  if RGBLine[x+1].rgbtGreen>CurGreen then
                    if RGBLineBottom[x-1].rgbtGreen>CurGreen then
                      if RGBLineBottom[x].rgbtGreen>CurGreen then
                        if RGBLineBottom[x+1].rgbtGreen>CurGreen then
                          Continue;
          ResultPointer:=PByte(NativeUInt(tmpBuffer)+CurrentByte);
          ResultPointer^:=(ResultPointer^ and not (1 shl CurrentBit));
        end;
      end
    else
      for y:=1 to DecodedFrame.Height-2 do
      begin
        ByteLine:=PByteArray(NativeUInt(DecodedFrame.Data)+y*DecodedFrame.Width);
        ByteLineTop:=PByteArray(NativeUInt(DecodedFrame.Data)+(y-1)*DecodedFrame.Width);
        ByteLineBottom:=PByteArray(NativeUInt(DecodedFrame.Data)+(y+1)*DecodedFrame.Width);
        for x:=1 to DecodedFrame.Width-2 do
        begin
          CurrentPixel:=y*DecodedFrame.Width+x;
          CurrentByte:=CurrentPixel div 8;
          CurrentBit:=CurrentPixel mod 8;
          CurGreen:=Round(ByteLine[x]*CurDec);
          if ByteLineTop[x-1]>CurGreen then
            if ByteLineTop[x]>CurGreen then
              if ByteLineTop[x+1]>CurGreen then
                if ByteLine[x-1]>CurGreen then
                  if ByteLine[x+1]>CurGreen then
                    if ByteLineBottom[x-1]>CurGreen then
                      if ByteLineBottom[x]>CurGreen then
                        if ByteLineBottom[x+1]>CurGreen then
                          Continue;
          ResultPointer:=PByte(NativeUInt(tmpBuffer)+CurrentByte);
          ResultPointer^:=(ResultPointer^ and not (1 shl CurrentBit));
        end;
      end;
    tmpDataSize:=SizeOf(TImageDataHeader)+(DecodedFrame.Width*DecodedFrame.Height div 8)+1;
    GetMem(AResultData,tmpDataSize);
    Move(AInputData^,AResultData^,SizeOf(TImageDataHeader));
    DecodedFrame:=AResultData;
    DecodedFrame.TimedDataHeader.DataHeader.Size:=tmpDataSize;
    DecodedFrame.ImageType:=itBit;
    Move(tmpBuffer^,DecodedFrame.Data^,(DecodedFrame.Width*DecodedFrame.Height div 8)+1);
  end;
end;

function TFindDark.GetGreenDec: Real;
begin
  FLock.Enter;
  result:=FGreenDec;
  FLock.Leave;
end;

procedure TFindDark.SetGreenDec(const Value: Real);
begin
  FLock.Enter;
  FGreenDec:=Value;
  FLock.Leave;
end;

end.
