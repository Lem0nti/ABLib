unit ABL.IA.Warp;

interface

uses
  ABL.Core.DirectThread, ABL.Core.BaseQueue, Types, ABL.VS.VSTypes, Math, SysUtils, ABL.Core.Debug;

type
  TWarpRect=array [0..3] of TPoint;

  TWarp=class(TDirectThread)
  private
    FWarpRect,srcQuad: TWarpRect;
    OldWidth, OldHeight, FWidth, FHeight: integer;
    FBytesPerPixel: byte;
    FromOffset: array of integer;
    exLeft, exRight: TPointF;
    function GetWarpRect: TWarpRect;
    procedure SetWarpRect(const Value: TWarpRect);
    function GetHeight: integer;
    function GetWidth: integer;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    property Height: integer read GetHeight;
    property WarpRect: TWarpRect read GetWarpRect write SetWarpRect;
    property Width: integer read GetWidth;
  end;

implementation

{ TWarp }

constructor TWarp.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue, AOutputQueue, AName);
  srcQuad[0].x:=0;
  srcQuad[0].y:=0;
  FWarpRect[0].x:=0;
  FWarpRect[0].y:=0;
  FWarpRect[1].x:=10000;
  FWarpRect[1].y:=0;
  FWarpRect[2].x:=10000;
  FWarpRect[2].y:=10000;
  FWarpRect[2].x:=0;
  FWarpRect[2].y:=10000;
  FWidth=0;
  FHeight=0;
  Start;
end;

procedure TWarp.DoExecute(var AInputData: Pointer; var AResultData: Pointer);
var
  ImageDataHeader: PImageDataHeader;
  tmpDataSize: Cardinal;
  tmpX,tmpY,tmpStepX,tmpStepY,ToOffset,Offset: integer;
  exLeft,exRight: TPointF;
  FromPixel,StartPixel,EndPixel: TPoint;
  exX,exY: Extended;
  PixelFrom,PixelTo: PByteArray;
  BytesPerPixel: byte;
begin
  try
    ImageDataHeader:=AInputData;
    if ImageDataHeader.ImageType in [itBGR,itGray] then
    begin
      if ImageDataHeader.ImageType=itBGR then
        BytesPerPixel:=3
      else
        BytesPerPixel:=1;
      FLock.Enter;
      try
        if (srcQuad[0].x+srcQuad[0].y=0)or(OldWidth<>ImageDataHeader.Width)or(OldHeight<>ImageDataHeader.Height) then
        begin
          srcQuad[0].x:=Round(FWarpRect[0].X*ImageDataHeader.Width/10000);
          srcQuad[0].y:=Round(FWarpRect[0].Y*ImageDataHeader.Height/10000);
          srcQuad[1].x:=Round(FWarpRect[1].X*ImageDataHeader.Width/10000);
          srcQuad[1].y:=Round(FWarpRect[1].Y*ImageDataHeader.Height/10000);
          srcQuad[2].x:=Round(FWarpRect[2].X*ImageDataHeader.Width/10000);
          srcQuad[2].y:=Round(FWarpRect[2].Y*ImageDataHeader.Height/10000);
          srcQuad[3].x:=Round(FWarpRect[3].X*ImageDataHeader.Width/10000);
          srcQuad[3].y:=Round(FWarpRect[3].Y*ImageDataHeader.Height/10000);
          if srcQuad[0].x+srcQuad[0].y=0 then
            exit;
          //высчитываем размеры итоговой картинки
          tmpX:=abs(srcQuad[0].X-srcQuad[1].X);
          tmpY:=abs(srcQuad[0].Y-srcQuad[1].Y);
          FWidth:=Round(sqrt(tmpX*tmpX+tmpY*tmpY));
          tmpX:=abs(srcQuad[2].X-srcQuad[3].X);
          tmpY:=abs(srcQuad[2].Y-srcQuad[3].Y);
          FWidth:=max(FWidth,Round(sqrt(tmpX*tmpX+tmpY*tmpY)));
          tmpX:=abs(srcQuad[0].X-srcQuad[3].X);
          tmpY:=abs(srcQuad[0].Y-srcQuad[3].Y);
          FHeight:=Round(sqrt(tmpX*tmpX+tmpY*tmpY));
          tmpX:=abs(srcQuad[2].X-srcQuad[1].X);
          tmpY:=abs(srcQuad[2].Y-srcQuad[1].Y);
          FHeight:=max(FHeight,Round(sqrt(tmpX*tmpX+tmpY*tmpY)));
          //размеры результата должны быть кратны 4
          while FWidth mod 4 = 0 do
            inc(FWidth);
          //дискретные шаги по периметру выделенного четырёхугольника
          //дельты для левой границы
          exLeft.X:=(srcQuad[3].X-srcQuad[0].X)/FHeight;
          exLeft.Y:=(srcQuad[3].Y-srcQuad[0].Y)/FHeight;
          //дельты для правой границы
          exRight.X:=(srcQuad[2].X-srcQuad[1].X)/FHeight;
          exRight.Y:=(srcQuad[2].Y-srcQuad[1].Y)/FHeight;
          SetLength(FromOffset,FWidth*FHeight);
          for tmpStepY := 0 to FHeight-1 do
          begin
            //левый конец для текущей строки
            StartPixel.X:=srcQuad[0].X+Round(tmpStepY*exLeft.X);
            StartPixel.Y:=srcQuad[0].Y+Round(tmpStepY*exLeft.Y);
            //правый конец для текущей строки
            EndPixel.X:=srcQuad[1].X+Round(tmpStepY*exRight.X);
            EndPixel.Y:=srcQuad[1].Y+Round(tmpStepY*exRight.Y);
            //шаг Х
            exX:=(EndPixel.X-StartPixel.X)/FWidth;
            //шаг У
            exY:=(EndPixel.Y-StartPixel.Y)/FWidth;
            for tmpStepX := 0 to FWidth-1 do
            begin
              //дельта Х
              FromPixel.X:=StartPixel.X+Round(tmpStepX*exX);
              FromPixel.Y:=StartPixel.Y+Round(tmpStepX*exY);
              FromOffset[tmpStepY*FWidth+tmpStepX]=(FromPixel.y*ImageDataHeader.Width+FromPixel.x)*BytesPerPixel;
            end;
          end;
        end;
        tmpDataSize:=SizeOf(TImageDataHeader)+FWidth*FHeight*BytesPerPixel;
        GetMem(AResultData,tmpDataSize);
        Move(AInputData,AResultData^,SizeOf(TImageDataHeader));
        ImageDataHeader:=AResultData;
        ImageDataHeader.Width:=FWidth;
        ImageDataHeader.Height:=FHeight;
      finally
        FLock.Leave;
      end;
      ToOffset:=0;
      PixelFrom:=PImageDataHeader(AInputData).Data;
      PixelTo:=ImageDataHeader.Data;
      for Offset:=0 to ImageDataHeader.Width*ImageDataHeader.Height-1 do
      begin
        if FromOffset[Offset]>=0 then
          move(PixelFrom[FromOffset[Offset]],PixelTo[ToOffset],BytesPerPixel)
        else
          FillChar(PixelTo[ToOffset],BytesPerPixel,255);
        ToOffset=ToOffset+BytesPerPixel;
      end;
      ImageDataHeader.TimedDataHeader.DataHeader.Size=sizeof(TImageDataHeader)+tmpDataSize;
    end;
  except on E: Exception do
    SendErrorMsg('TWarp.DoExecute 154: '+e.ClassName+' - '+e.Message);
  end;
end;

function TWarp.GetHeight: integer;
begin
  FLock.Enter;
  try
    result:=FHeight;
  finally
    FLock.Leave;
  end;
end;

function TWarp.GetWarpRect: TWarpRect;
begin
  FLock.Enter;
  try
    result:=FWarpRect;
  finally
    FLock.Leave;
  end;
end;

function TWarp.GetWidth: integer;
begin
  FLock.Enter;
  try
    result:=FWidth;
  finally
    FLock.Leave;
  end;
end;

procedure TWarp.SetWarpRect(const Value: TWarpRect);
begin
  FLock.Enter;
  try
    FWarpRect:=Value;
    srcQuad[0].x:=0;
    srcQuad[0].y:=0;
  finally
    FLock.Leave;
  end;
end;

end.
