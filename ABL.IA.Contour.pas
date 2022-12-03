unit ABL.IA.Contour;

interface

uses
  ABL.Core.DirectThread, ABL.Core.BaseQueue, ABL.VS.VSTypes, SysUtils;

type
  TContour=class(TDirectThread)
  private
    tmpBuffer: Pointer;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    destructor Destroy; override;
  end;

implementation

{ TContour }

constructor TContour.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  GetMem(tmpBuffer,2048*2048);
  Start;
end;

destructor TContour.Destroy;
begin
  FreeMem(tmpBuffer);
  inherited;
end;

procedure TContour.DoExecute(var AInputData, AResultData: Pointer);
var
  ImageDataHeader: PImageDataHeader;
  Offset,CurByte,CurBit,x,y,tmpDataSize: integer;
  FromData,ToData: PByteArray;
begin
  ImageDataHeader=AInputData;
  if (ImageDataHeader.TimedDataHeader.DataHeader.Magic=16961)and(ImageDataHeader.TimedDataHeader.DataHeader.Version=0)and(ImageDataHeader.TimedDataHeader.DataHeader.DataType=2)and
      (ImageDataHeader.ImageType=itBit) then
  begin
    tmpDataSize:=ImageDataHeader.Width*ImageDataHeader.Height div 8+1;
    FillChar(tmpBuffer,tmpDataSize,255);
    FromData:=ImageDataHeader.Data;
    ToData:=tmpBuffer;
    for y:=0 to ImageDataHeader.Height-1 do
      for x:=0 to ImageDataHeader.Width-1 do
      begin
        Offset=y*ImageDataHeader.Width+x;
        CurByte=Offset div 8;
        CurBit=Offset mod 8;
        //текущий пиксель чёрный?
        if (FromData[CurByte] shr CurBit) and 1 = 0 then
        begin
          //вариант для 4 элементов окрестности
          //инвертировать ... сделать белое чёрным
          if y>0 then
          begin
            Offset:=(y-1)*ImageDataHeader.Width+x;
            CurByte=Offset div 8;
            CurBit=Offset mod 8;
            if (FromData[CurByte] shr CurBit) and 1 = 1 then
              ToData[CurByte]:=ToData[CurByte] or (1 shl CurBit);
          end;
          if x>0 then
          begin
            Offset:=y*ImageDataHeader.Width+x-1;
            CurByte=Offset div 8;
            CurBit=Offset mod 8;
            if (FromData[CurByte] shr CurBit) and 1 = 1 then
              ToData[CurByte]:=ToData[CurByte] or (1 shl CurBit);
          end;
          if x<ImageDataHeader.Width-1 then
          begin
            Offset:=y*ImageDataHeader.Width+x+1;
            CurByte=Offset div 8;
            CurBit=Offset mod 8;
            if (FromData[CurByte] shr CurBit) and 1 = 1 then
              ToData[CurByte]:=ToData[CurByte] or (1 shl CurBit);
          end;
          if y<ImageDataHeader.Height-1 then
          begin
            Offset:=(y+1)*ImageDataHeader.Width+x;
            CurByte=Offset div 8;
            CurBit=Offset mod 8;
            if (FromData[CurByte] shr CurBit) and 1 = 1 then
              ToData[CurByte]:=ToData[CurByte] or (1 shl CurBit);
          end;
        end;
      end;
    move(tmpBuffer^,ImageDataHeader.Data^,tmpDataSize);
    AResultData:=AInputData;
    AInputData:=nil;
  end;
end;

end.
