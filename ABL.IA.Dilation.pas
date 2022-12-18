unit ABL.IA.Dilation;

interface

uses
  ABL.Core.DirectThread, ABL.Core.BaseQueue, ABL.VS.VSTypes, SysUtils;

type
  TDilation=class(TDirectThread)
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

constructor TDilation.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  GetMem(tmpBuffer,2048*2048);
  Start;
end;

destructor TDilation.Destroy;
begin
  Stop;
  FreeMem(tmpBuffer);
  inherited;
end;

procedure TDilation.DoExecute(var AInputData, AResultData: Pointer);
var
  ImageDataHeader: PImageDataHeader;
  x,y,Offset,CurByte,CurBit,xtmp,ytmp: integer;
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
          //все вокруг зануляем
          for ytmp:=y-1 to y+1 do
            for xtmp:=x-1 to x+1 do
            begin
              Offset:=ytmp*ImageDataHeader.Width+xtmp;
              CurByte:=Offset div 8;
              CurBit:=Offset mod 8;
              ByteTo[CurByte]:=(ByteTo[CurByte] and not (1 shl CurBit));
            end;
      end;
    move(tmpBuffer^,ImageDataHeader.Data^,tmpDataSize);
    AResultData:=AInputData;
    AInputData:=nil;
  end;
end;

end.
