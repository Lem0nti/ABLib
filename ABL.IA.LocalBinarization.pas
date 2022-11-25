unit ABL.IA.LocalBinarization;

interface

uses
  ABL.Core.DirectThread, ABL.VS.VSTypes, ABL.Core.BaseQueue, Math, ABL.IA.IATypes, SyncObjs;

type
  TLocalBinarization=class(TDirectThread)
  private
    Integral: array of array of Cardinal;
    FBuffer: Pointer;
    FOffset: ShortInt;
    FRadius: byte;
    function GetOffset: ShortInt;
    function GetRadius: byte;
    procedure SetOffset(const Value: ShortInt);
    procedure SetRadius(const Value: byte);
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    destructor Destroy; override;
    property Offset: ShortInt read GetOffset write SetOffset;
    property Radius: byte read GetRadius write SetRadius;
  end;

implementation

{ TBradley }

constructor TLocalBinarization.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  GetMem(FBuffer,2048*2048*3);
  FRadius:=8;
  FOffset:=30;
  Start;
end;

destructor TLocalBinarization.Destroy;
begin
  FreeMem(FBuffer);
  inherited;
end;

procedure TLocalBinarization.DoExecute(var AInputData, AResultData: Pointer);
var
  DecodedFrame: PImageDataHeader;
  x,y,xFrom,xTo,yFrom,yTo: integer;
  RGBArrayFrom: PRGBArray;
  Neighbor,WholeSquare,PixelOffset,CurrentByte: integer;
  tmpRadius: byte;
  tmpOffset: ShortInt;
  DecValue: Extended;
  CurrentBit: SmallInt;
  BW: PByte;
begin
  DecodedFrame:=AInputData;
  if DecodedFrame^.ImageType=itBGR then
  begin
    //интегральное
    SetLength(Integral,DecodedFrame.Width,DecodedFrame.Height);
    RGBArrayFrom:=Pointer(NativeUInt(AInputData)+SizeOf(TImageDataHeader));
    //сначала все нулевые, так быстрее
    Integral[0,0]:=RGBArrayFrom[0].rgbtGreen;
    for y := 1 to DecodedFrame.Height-1 do
      Integral[0,y]:=Integral[0,y-1]+RGBArrayFrom[y*DecodedFrame.Width].rgbtGreen;
    for x := 1 to DecodedFrame.Width-1 do
      Integral[x,0]:=Integral[x-1,0]+RGBArrayFrom[x].rgbtGreen;
    for y := 1 to DecodedFrame.Height-1 do
      for x := 1 to DecodedFrame.Width-1 do
        Integral[x,y]:=RGBArrayFrom[y*DecodedFrame.Width+x].rgbtGreen+Integral[x,y-1]+Integral[x-1,y]-Integral[x-1,y-1];
    //бинаризация
    FLock.Enter;
    tmpRadius:=FRadius;
    tmpOffset:=FOffset;
    FLock.Leave;
    DecValue:=(1-tmpOffset/100);
    FillChar(FBuffer^,(DecodedFrame.Width*DecodedFrame.Height div 8)+1,255);
    //сначала все приграничные, так быстрее
    for y := 0 to tmpRadius-1 do
    begin
      RGBArrayFrom:=Pointer(NativeUInt(AInputData)+SizeOf(TImageDataHeader)+y*DecodedFrame.Width*3);
      yTo:=y+tmpRadius;
      for x := 0 to DecodedFrame.Width-1 do
      begin
        //среднее
        xFrom:=x-tmpRadius;
        if xFrom<0 then
          xFrom:=0;
        xTo:=x+tmpRadius;
        if xTo>DecodedFrame.Width-1 then
          xTo:=DecodedFrame.Width-1;
        Neighbor:=Integral[xTo,yTo];
        if xFrom>0 then
          Neighbor:=Neighbor-Integral[xFrom-1,yTo];
        Neighbor:=Round(DecValue*Neighbor/((xTo-XFrom)*yTo));
        //больше-меньше?
        if RGBArrayFrom[x].rgbtGreen<Neighbor then
        begin
          PixelOffset:=y*DecodedFrame.Width+x;
          CurrentByte:=PixelOffset div 8;
          CurrentBit:=PixelOffset mod 8;
          BW:=PByte(NativeUInt(FBuffer)+CurrentByte);
          BW^:=(BW^ and not (1 shl CurrentBit));
        end;
      end;
    end;
    WholeSquare:=Round(Power(tmpRadius*2,2));
    DecValue:=DecValue/WholeSquare;
    for y := tmpRadius to DecodedFrame.Height-1 do
    begin
      if Terminated then
        exit;
      RGBArrayFrom:=Pointer(NativeUInt(AInputData)+SizeOf(TImageDataHeader)+y*DecodedFrame.Width*3);
      yFrom:=y-tmpRadius;
      yTo:=y+tmpRadius;
      if yTo>DecodedFrame.Height-1 then
        yTo:=DecodedFrame.Height-1;
      for x := 0 to DecodedFrame.Width-1 do
      begin
        //среднее
        xFrom:=x-tmpRadius;
        if xFrom<0 then
          xFrom:=0;
        xTo:=x+tmpRadius;
        if xTo>DecodedFrame.Width-1 then
          xTo:=DecodedFrame.Width-1;
        Neighbor:=Integral[xTo,yTo]-Integral[xTo,yFrom-1];
        if xFrom>0 then
          Neighbor:=Neighbor-Integral[xFrom-1,yTo];
        if xFrom>0 then
          Neighbor:=Neighbor+Integral[xFrom-1,yFrom-1];
        Neighbor:=Round(DecValue*Neighbor);
        //больше-меньше?
        if RGBArrayFrom[x].rgbtGreen<Neighbor then
        begin
          PixelOffset:=y*DecodedFrame.Width+x;
          CurrentByte:=PixelOffset div 8;
          CurrentBit:=PixelOffset mod 8;
          BW:=PByte(NativeUInt(FBuffer)+CurrentByte);
          BW^:=(BW^ and not (1 shl CurrentBit));
        end;
      end;
    end;
    DecodedFrame.ImageType:=itBit;
    if assigned(FOutputQueue) then
    begin
      DecodedFrame.TimedDataHeader.DataHeader.Size:=(DecodedFrame.Width*DecodedFrame.Height div 8)+1+SizeOf(TImageDataHeader);
      Move(FBuffer^,Pointer(NativeUInt(AInputData)+SizeOf(TImageDataHeader))^,(DecodedFrame.Width*DecodedFrame.Height div 8)+1);
      AResultData:=AInputData;
      AInputData:=nil;
    end;
  end;
end;

function TLocalBinarization.GetOffset: ShortInt;
begin
  FLock.Enter;
  result:=FOffset;
  FLock.Leave;
end;

function TLocalBinarization.GetRadius: byte;
begin
  FLock.Enter;
  result:=FRadius;
  FLock.Leave;
end;

procedure TLocalBinarization.SetOffset(const Value: ShortInt);
begin
  FLock.Enter;
  FOffset:=Value;
  FLock.Leave;
end;

procedure TLocalBinarization.SetRadius(const Value: byte);
begin
  FLock.Enter;
  FRadius:=Value;
  FLock.Leave;
end;

end.
