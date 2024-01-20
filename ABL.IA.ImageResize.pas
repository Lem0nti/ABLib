unit ABL.IA.ImageResize;

interface

uses
  ABL.Core.DirectThread, ABL.VS.VSTypes, Types, SyncObjs, ABL.Core.BaseQueue, SysUtils,
  ABL.IA.IATypes;

type
  TResizeAlgorythm = (raHearHeighbour,raAverageBright);

  TRGBWhole=record
    Red, Green, Blue, Count: integer;
  end;

  TImageResize=class(TDirectThread)
  private
    FWidth, FHeight: word;
    FAlgorythm: TResizeAlgorythm;
    function GetHeight: word;
    function GetWidth: word;
    procedure SetHeight(const Value: word);
    procedure SetWidth(const Value: word);
    function GetAlgorythm: TResizeAlgorythm;
    procedure SetAlgorythm(const Value: TResizeAlgorythm);
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    procedure SetSize(AWidth, AHeight: word);
    property Algorythm: TResizeAlgorythm read GetAlgorythm write SetAlgorythm;
    property Height: word read GetHeight write SetHeight;
    property Width: word read GetWidth write SetWidth;
  end;

implementation

{ TImageResize }

constructor TImageResize.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  FAlgorythm:=raHearHeighbour;
  Active:=true;
end;

procedure TImageResize.DoExecute(var AInputData, AResultData: Pointer);
var
  DecodedFrame, OutputFrame: PImageDataHeader;
  tmpWidth, tmpHeight: word;
  wh,hh: Extended;
  x,y: integer;
  OffsetTo,OffsetFrom,sz: Cardinal;
  BytesPerPixel: byte;
  tmpAlgorythm: TResizeAlgorythm;
  ResultPreMatrix: array of TRGBWhole;
  RGBArray: PRGBArray;
  tmpExtended: Extended;
begin
  DecodedFrame:=AInputData;
  if DecodedFrame.ImageType in [itBGR,itGray] then
  begin
    FLock.Enter;
    tmpWidth:=FWidth;
    tmpHeight:=FHeight;
    tmpAlgorythm:=FAlgorythm;
    FLock.Leave;
    wh:=DecodedFrame.Width/tmpWidth;
    hh:=DecodedFrame.Height/tmpHeight;
    OffsetTo:=0;
    if DecodedFrame.ImageType=itBGR then
      BytesPerPixel:=3
    else
      BytesPerPixel:=1;
    if (DecodedFrame.Width<tmpWidth) or (DecodedFrame.Height<tmpHeight) then //надо ли увеличивать картинку
    begin
      sz:=tmpWidth*tmpHeight*BytesPerPixel+SizeOf(TImageDataHeader);
      GetMem(AResultData,sz);
      move(AInputData^,AResultData^,SizeOf(TImageDataHeader));
      OutputFrame:=AResultData;
      OutputFrame.Height:=tmpHeight;
      OutputFrame.Width:=tmpWidth;
      OutputFrame.TimedDataHeader.DataHeader.Size:=sz;
      for y:=0 to tmpHeight-1 do
        for x:=0 to tmpWidth-1 do
        begin
          OffsetFrom:=(round(y*hh)*DecodedFrame.Width+round(x*wh))*BytesPerPixel;
          Move(PByte(NativeUInt(DecodedFrame.Data)+OffsetFrom)^,PByte(NativeUInt(OutputFrame.Data)+OffsetTo)^,BytesPerPixel);
          OffsetTo:=OffsetTo+BytesPerPixel;
        end;
        AResultData:=OutputFrame;
    end
    else
    begin
      if (DecodedFrame.Width>tmpWidth) or (DecodedFrame.Height>tmpHeight) then //надо ли уменьшать картинку
      begin
        if tmpAlgorythm=raHearHeighbour then
          for y:=0 to tmpHeight-1 do
            for x:=0 to tmpWidth-1 do
            begin
              OffsetFrom:=(round(y*hh)*DecodedFrame.Width+round(x*wh))*BytesPerPixel;
              Move(PByte(NativeUInt(DecodedFrame.Data)+OffsetFrom)^,PByte(NativeUInt(DecodedFrame.Data)+OffsetTo)^,BytesPerPixel);
              OffsetTo:=OffsetTo+BytesPerPixel;
            end
        else
        begin
          SetLength(ResultPreMatrix,tmpWidth*tmpHeight);
          FillChar(ResultPreMatrix[0],tmpWidth*tmpHeight*SizeOf(TRGBWhole),0);
          RGBArray:=DecodedFrame.Data;
          for y:=0 to DecodedFrame.Height-1 do
            for x:=0 to DecodedFrame.Width-1 do
            begin
              OffsetFrom:=(y*DecodedFrame.Width+x);
              OffsetTo:=(round(y/hh)*tmpWidth+round(x/wh));
              if OffsetTo<tmpWidth*tmpHeight then
              begin
                ResultPreMatrix[OffsetTo].Red:=ResultPreMatrix[OffsetTo].Red+RGBArray[OffsetFrom].rgbtRed;
                ResultPreMatrix[OffsetTo].Green:=ResultPreMatrix[OffsetTo].Green+RGBArray[OffsetFrom].rgbtGreen;
                ResultPreMatrix[OffsetTo].Blue:=ResultPreMatrix[OffsetTo].Blue+RGBArray[OffsetFrom].rgbtBlue;
                inc(ResultPreMatrix[OffsetTo].Count);
              end;
            end;
          //собираем усреднённую картинку
          for y:=0 to tmpHeight-1 do
            for x:=0 to tmpWidth-1 do
            begin
              OffsetFrom:=(y*tmpWidth+x);
              tmpExtended:=ResultPreMatrix[OffsetFrom].Blue/ResultPreMatrix[OffsetFrom].Count;
              RGBArray[OffsetFrom].rgbtBlue:=Round(tmpExtended);
              tmpExtended:=ResultPreMatrix[OffsetFrom].Green/ResultPreMatrix[OffsetFrom].Count;
              RGBArray[OffsetFrom].rgbtGreen:=Round(tmpExtended);
              tmpExtended:=ResultPreMatrix[OffsetFrom].Red/ResultPreMatrix[OffsetFrom].Count;
              RGBArray[OffsetFrom].rgbtRed:=Round(tmpExtended);
            end;
        end;
        DecodedFrame.Width:=tmpWidth;
        DecodedFrame.Height:=tmpHeight;
//        ABLSaveAsBMP(DecodedFrame,'D:\Video\qwe.bmp');
      end;
      AResultData:=AInputData;
      AInputData:=nil;
    end;
  end;
end;

function TImageResize.GetAlgorythm: TResizeAlgorythm;
begin
  FLock.Enter;
  try
    result:=FAlgorythm;
  finally
    FLock.Leave;
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

procedure TImageResize.SetAlgorythm(const Value: TResizeAlgorythm);
begin
  FLock.Enter;
  try
    FAlgorythm:=Value;
  finally
    FLock.Leave;
  end;
end;

procedure TImageResize.SetHeight(const Value: word);
begin
  FLock.Enter;
  try
    if Value>0 then
      FHeight:=Value;
  finally
    FLock.Leave;
  end;
end;

procedure TImageResize.SetSize(AWidth, AHeight: word);
begin
  FLock.Enter;
  try
    if AHeight>0 then
      FHeight:=AHeight;
    if AWidth>0 then
      FWidth:=AWidth;
  finally
    FLock.Leave;
  end;
end;

procedure TImageResize.SetWidth(const Value: word);
begin
  FLock.Enter;
  try
    if Value>0 then
      FWidth:=Value;
  finally
    FLock.Leave;
  end;
end;

end.
