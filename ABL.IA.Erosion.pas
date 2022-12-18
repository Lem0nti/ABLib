unit ABL.IA.Erosion;

interface

uses
  ABL.Core.DirectThread, ABL.Core.BaseQueue, ABL.VS.VSTypes, SysUtils;

type
  TErosion=class(TDirectThread)
  private
    tmpBuffer: Pointer;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    destructor Destroy; override;
  end;

implementation

{ TErosion }

constructor TErosion.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  GetMem(tmpBuffer,2048*2048);
  Start;
end;

destructor TErosion.Destroy;
begin
  Stop;
  FreeMem(tmpBuffer);
  inherited;
end;

procedure TErosion.DoExecute(var AInputData, AResultData: Pointer);
var
  ImageDataHeader: PImageDataHeader;
  x,y,Offset,CurByte,CurBit: integer;
  ByteFrom,ByteTo: PByteArray;
  tmpDataSize: Cardinal;
begin
  ImageDataHeader:=AInputData;
  if ImageDataHeader.ImageType=itBit then
  begin
    tmpDataSize:=ImageDataHeader.Width*ImageDataHeader.Height div 8+1;
    move(ImageDataHeader.Data^,tmpBuffer^,tmpDataSize);
    ByteFrom:=ImageDataHeader.Data;
    ByteTo:=tmpBuffer;
    for y:=1 to ImageDataHeader.Height-2 do
      for x:=1 to ImageDataHeader.Width-2 do
      begin
        Offset:=y*ImageDataHeader.Width+x;
        CurByte:=Offset div 8;
        CurBit:=Offset mod 8;
        //текущий пиксель чёрный?
        if (ByteFrom[CurByte] shr CurBit) and 1 = 0 then
        begin
          //если в окрестности есть хоть один белый, то зануляем
          Offset:=(y-1)*ImageDataHeader.Width+x;
          CurByte:=Offset div 8;
          CurBit:=Offset mod 8;
          if (ByteFrom[CurByte] shr CurBit) and 1 = 0 then
          begin
            Offset:=y*ImageDataHeader.Width+x-1;
            CurByte:=Offset div 8;
            CurBit:=Offset mod 8;
            if (ByteFrom[CurByte] shr CurBit) and 1 = 0 then
            begin
              Offset:=y*ImageDataHeader.Width+x+1;
              CurByte:=Offset div 8;
              CurBit:=Offset mod 8;
              if (ByteFrom[CurByte] shr CurBit) and 1 = 0 then
              begin
                Offset:=(y+1)*ImageDataHeader.Width+x;
                CurByte:=Offset div 8;
                CurBit:=Offset mod 8;
                if (ByteFrom[CurByte] shr CurBit) and 1 = 0 then
                  Continue;
              end;
            end;
          end;
          Offset:=y*ImageDataHeader.Width+x;
          CurByte:=Offset div 8;
          CurBit:=Offset mod 8;
          ByteTo[CurByte]:=ByteTo[CurByte] or (1 shl CurBit);
        end;
      end;
    move(tmpBuffer^,ImageDataHeader.Data^,tmpDataSize);
    AResultData:=AInputData;
    AInputData:=nil;
  end;
end;

end.
