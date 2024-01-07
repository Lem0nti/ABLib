unit ABL.IA.OnlyMotion;

interface

uses
  ABL.Core.DirectThread, ABL.VS.VSTypes, SyncObjs, Windows, ABL.Core.BaseQueue, SysUtils, ABL.VS.BMPSaver;

type
  TOnlyMotion=class(TDirectThread)
  private
    Ethalon: array of byte;
    FSensivity: byte;
    FCols, FRows: word;
    function GetCols: word;
    function GetRows: word;
    function GetSensivity: word;
    procedure SetCols(const Value: word);
    procedure SetRows(const Value: word);
    procedure SetSensivity(const Value: word);
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    procedure SetGrid(ACols, ARows: word);
    property Cols: word read GetCols write SetCols;
    property Rows: word read GetRows write SetRows;
    property Sensivity: word read GetSensivity write SetSensivity;
  end;

implementation

{ TIfMotion }

constructor TOnlyMotion.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  FRows:=16;
  FCols:=16;
  FSensivity:=44;
  Active:=true;
end;

procedure TOnlyMotion.DoExecute(var AInputData, AResultData: Pointer);
var
  Offset,x,y,OffsetFrom,MZone: integer;
  tmpData: PByteArray;
  DecodedFrame: PImageDataHeader;
  rcWidth,rcHeight: Real;
  tmpRows,tmpCols: word;
  CurMotion,tmpEthalon: TByteArray;
  Can: boolean;

  procedure ApplyAsEthalon;
  var
    ax,ay: integer;
  begin
    Offset:=0;
    SetLength(Ethalon,tmpRows*tmpCols);
  //  if DecodedFrame.ImageType=itBGR then
      for ay := 0 to tmpRows-1 do
        for ax := 0 to tmpCols-1 do
        begin
          OffsetFrom:=(round(ay*rcHeight)*DecodedFrame.Width+round(x*rcWidth))*3+1;  //+1 - работа с зелёным
          Ethalon[Offset]:=tmpData[OffsetFrom];
          inc(Offset);
        end
//    else
//      for ay := 0 to FRows-1 do
//        for ax := 0 to FCols-1 do
//        begin
//          ByteArray:=PByteArray(NativeUInt(DecodedFrame.Data)+Round(ay*rcHeight)*DecodedFrame.Width+Round(ax*rcWidth));
//          Ethalon[Offset]:=ByteArray[0];
//          inc(Offset);
//        end
  end;

begin
  DecodedFrame:=AInputData;
  if DecodedFrame.ImageType=itBGR then
  begin
    FLock.Enter;
    tmpRows:=FRows;
    tmpCols:=FCols;
    FLock.Leave;
    rcWidth:=DecodedFrame.Width/tmpCols;
    rcHeight:=DecodedFrame.Height/tmpRows;
    tmpData:=DecodedFrame.Data;
    if Length(Ethalon)=0 then
      ApplyAsEthalon
    else
    begin
      //движение
      Offset:=0;
      FillChar(CurMotion[0],tmpRows*tmpCols,0);
      Can:=false;
      //unsigned char tmpEthalon[tmpRows*tmpCols];
      for y:=0 to DecodedFrame.Height-1 do
        for x:=0 to DecodedFrame.Width-1 do
        begin
          MZone:=round(y/rcHeight)*tmpCols+round(x/rcWidth);
          OffsetFrom:=(y*DecodedFrame.Width+x)*3+1;  //+1 - работа с зелёным
          if MZone<tmpRows*tmpCols then  //расчёты пикселей последних линий при округлении могут выйти за сетку сканирования
          begin
            if CurMotion[MZone]=0 then
            begin
              CurMotion[MZone]:=1;
              tmpEthalon[MZone]:=tmpData[OffsetFrom];
              if abs(Ethalon[MZone]-tmpEthalon[MZone])>FSensivity then
              begin
                CurMotion[MZone]:=2;
                Can:=true;
              end;
            end;
            if CurMotion[MZone]=1 then
            begin
              tmpData[OffsetFrom-1]:=255;
              tmpData[OffsetFrom]:=255;
              tmpData[OffsetFrom+1]:=255;
            end;
          end
          else
          begin
            tmpData[OffsetFrom-1]:=255;
            tmpData[OffsetFrom]:=255;
            tmpData[OffsetFrom+1]:=255;
          end;
        end;
//      else
//        for y := 0 to tmpRows-1 do
//        begin
//          for x := 0 to tmpCols-1 do
//          begin
//            ByteArray:=PByteArray(NativeUInt(DecodedFrame.Data)+Round(y*rcHeight)*DecodedFrame.Width+Round(x*rcWidth));
//            if abs(Ethalon[Offset]-ByteArray[0])>Sensivity then
//            begin
//              inc(Can);
//              if Can>1 then
//                break;
//            end;
//            inc(Offset);
//          end;
//          if Can>1 then
//            break;
//        end;
      if Can then
      begin
        Move(tmpEthalon[0],Ethalon[0],tmpRows*tmpCols);
        //ApplyAsEthalon;
        //if assigned(FOutputQueue) then
        //begin
        AResultData:=AInputData;
        //ABLSaveAsBMP(DecodedFrame,'D:\Video\'+IntToStr(FIterationCounter)+'.bmp');
        AInputData:=nil;
        //end;
      end;
    end;
  end;
end;

function TOnlyMotion.GetCols: word;
begin
  FLock.Enter;
  try
    result:=FCols;
  finally
    FLock.Leave;
  end;
end;

function TOnlyMotion.GetRows: word;
begin
  FLock.Enter;
  try
    result:=FRows
  finally
    FLock.Leave;
  end;
end;

function TOnlyMotion.GetSensivity: word;
begin
  FLock.Enter;
  try
    result:=FSensivity;
  finally
    FLock.Leave;
  end;
end;

procedure TOnlyMotion.SetCols(const Value: word);
begin
  FLock.Enter;
  try
    FCols:=Value;
    SetLength(Ethalon,0);
  finally
    FLock.Leave;
  end;
end;

procedure TOnlyMotion.SetGrid(ACols, ARows: word);
begin
  FLock.Enter;
  try
    FCols:=ACols;
    FRows:=ARows;
    SetLength(Ethalon,0);
  finally
    FLock.Leave;
  end;
end;

procedure TOnlyMotion.SetRows(const Value: word);
begin
  FLock.Enter;
  try
    FRows:=Value;
    SetLength(Ethalon,0);
  finally
    FLock.Leave;
  end;
end;

procedure TOnlyMotion.SetSensivity(const Value: word);
begin
  FLock.Enter;
  try
    FSensivity:=Value;
  finally
    FLock.Leave;
  end;
end;

end.
