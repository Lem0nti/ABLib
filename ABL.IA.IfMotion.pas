unit ABL.IA.IfMotion;

interface

uses
  ABL.Core.DirectThread, ABL.VS.VSTypes, SyncObjs, Windows, ABL.Core.BaseQueue;

type
  TIfMotion=class(TDirectThread)
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

constructor TIfMotion.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  FRows:=16;
  FCols:=16;
  FSensivity:=44;
  Active:=true;
end;

procedure TIfMotion.DoExecute(var AInputData, AResultData: Pointer);
var
  Offset,Can,x,y: integer;
  RGBTriple: PRGBTriple;
  DecodedFrame: PImageDataHeader;
  rcWidth,rcHeight: Real;
  tmpRows,tmpCols: word;

  procedure ApplyAsEthalon;
  var
    ax,ay: integer;
  begin
    Offset:=0;
    SetLength(Ethalon,FRows*FCols);
    for ay := 0 to FRows-1 do
      for ax := 0 to FCols-1 do
      begin
        RGBTriple:=PRGBTriple(NativeUInt(DecodedFrame.Data)+(Round(ay*rcHeight)*DecodedFrame.Width+Round(ax*rcWidth))*3);
        Ethalon[Offset]:=RGBTriple.rgbtGreen;
        inc(Offset);
      end;
  end;

begin
  DecodedFrame:=AInputData;
    FLock.Enter;
    tmpRows:=FRows;
    tmpCols:=FCols;
    FLock.Leave;
    if Length(Ethalon)=0 then
      ApplyAsEthalon
    else
    begin
      rcWidth:=DecodedFrame.Width/tmpCols;
      rcHeight:=DecodedFrame.Height/tmpRows;
      //движение
      Can:=0;
      Offset:=0;
      for y := 0 to tmpRows-1 do
      begin
        for x := 0 to tmpCols-1 do
        begin
          RGBTriple:=PRGBTriple(NativeUInt(DecodedFrame.Data)+(Round(y*rcHeight)*DecodedFrame.Width+Round(x*rcWidth))*3);
          if abs(Ethalon[Offset]-RGBTriple.rgbtGreen)>Sensivity then
          begin
            inc(Can);
            if Can>1 then
              break;
          end;
          inc(Offset);
        end;
        if Can>1 then
          break;
      end;
      if Can>1 then
      begin
        ApplyAsEthalon;
        if assigned(FOutputQueue) then
        begin
          AResultData:=AInputData;
          AInputData:=nil;
        end;
      end;
    end;
end;

function TIfMotion.GetCols: word;
begin
  FLock.Enter;
  try
    result:=FCols;
  finally
    FLock.Leave;
  end;
end;

function TIfMotion.GetRows: word;
begin
  FLock.Enter;
  try
    result:=FRows
  finally
    FLock.Leave;
  end;
end;

function TIfMotion.GetSensivity: word;
begin
  FLock.Enter;
  try
    result:=FSensivity;
  finally
    FLock.Leave;
  end;
end;

procedure TIfMotion.SetCols(const Value: word);
begin
  FLock.Enter;
  try
    FCols:=Value;
    SetLength(Ethalon,0);
  finally
    FLock.Leave;
  end;
end;

procedure TIfMotion.SetGrid(ACols, ARows: word);
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

procedure TIfMotion.SetRows(const Value: word);
begin
  FLock.Enter;
  try
    FRows:=Value;
    SetLength(Ethalon,0);
  finally
    FLock.Leave;
  end;
end;

procedure TIfMotion.SetSensivity(const Value: word);
begin
  FLock.Enter;
  try
    FSensivity:=Value;
  finally
    FLock.Leave;
  end;
end;

end.
