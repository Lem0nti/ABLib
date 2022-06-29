unit ABL.Render.DirectRender;

interface

uses
  ABL.Core.DirectThread, ABL.Render.Drawer, ABL.VS.VSTypes, ABL.VS.DecodedItem, SysUtils,
  SyncObjs,
  DateUtils, ABL.Core.Debug;

type

  { TDirectRender }

  TDirectRender=class(TDirectThread)
  private
    FDrawer: TDrawer;
    FWidth, FHeight: integer;
    FLastPicture: PDecodedFrame;
    SkipThru: TDateTime;
    FHandle: THandle;
    procedure UpdateSizes;
    function GetHandle: THandle;
    function GetHeight: integer;
    function GetWidth: integer;
    procedure SetHandle(const Value: THandle);
    procedure SetHeight(const Value: integer);
    procedure SetWidth(const Value: integer);
    function GetCameraName: string;
    procedure SetCameraName(const Value: string);
  protected
    {$IFDEF FPC}
    procedure ClearData(AData: Pointer); override;
    {$ENDIF}
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AName: string = ''); override;
    destructor Destroy; override;
    procedure SetSize(AWidth, AHeight: integer);
    procedure SkipSecond;
    procedure UpdateScreen;
    property CameraName: string read GetCameraName write SetCameraName;
    property Drawer: TDrawer read FDrawer;
    property Handle: THandle read GetHandle write SetHandle;
    property Height: integer read GetHeight write SetHeight;
    property Width: integer read GetWidth write SetWidth;
  end;

implementation

{ TDirectRender }

constructor TDirectRender.Create(AName: string);
begin
  inherited Create(nil,nil,AName);
  FInputQueue:=TDecodedItem.Create(ClassName+'_'+AName+'_Input_'+IntToStr(FID));
  FDrawer:=TDrawer.Create(0,ClassName+'_'+AName+'_Drawer_'+IntToStr(FID));
  FWidth:=1920;
  FHeight:=1080;
  SkipThru:=0;
  FLastPicture:=nil;
  Active:=true;
  new(FLastPicture);
  FLastPicture.Time:=0;
  GetMem(FLastPicture.Data,3000*2000*3);
end;

destructor TDirectRender.Destroy;
begin
  if assigned(FDrawer) then
    FreeAndNil(FDrawer);
  FreeMem(FLastPicture.Data);
  Dispose(FLastPicture);
  inherited;
end;

procedure TDirectRender.DoExecute(var AInputData: Pointer;
  var AResultData: Pointer);
var
  rData: PDecodedFrame;
  DrawResult: integer;
  tmpStr: string;
begin
  rData:=PDecodedFrame(AInputData);
  try
    if (SkipThru<now) and assigned(FDrawer) then
    begin
      DrawResult:=FDrawer.Draw(rData);
      Move(rData.Data^,FLastPicture.Data^,rData.Width*rData.Height*3);
      FLastPicture.Width:=rData.Width;
      FLastPicture.Height:=rData.Height;
      FLastPicture.Time:=rData.Time;
      if DrawResult<0 then
        SkipSecond;
    end;
  finally
    try
      if assigned(rData) then
        FreeMem(rData^.Data);
    except on e: Exception do
      begin

        tmpStr:='rData.Width='+IntToStr(rData.Width)+', DrawResult='+IntToStr(DrawResult);
        SendErrorMsg('TDirectRender('+FName+').DoExecute 103, '+tmpStr+': '+e.ClassName+' - '+e.Message);
      end;
    end;
  end;
end;

function TDirectRender.GetCameraName: string;
begin
  result:=Drawer.CameraName;
end;

function TDirectRender.GetHandle: THandle;
begin
  FLock.Enter;
  try
    result:=FHandle;
  finally
    FLock.Leave;
  end;
end;

function TDirectRender.GetHeight: integer;
begin
  FLock.Enter;
  try
    result:=FHeight;
  finally
    FLock.Leave;
  end;
end;

function TDirectRender.GetWidth: integer;
begin
  FLock.Enter;
  try
    result:=FWidth;
  finally
    FLock.Leave;
  end;
end;

procedure TDirectRender.SetCameraName(const Value: string);
begin
  Drawer.CameraName:=Value;
end;

procedure TDirectRender.SetHandle(const Value: THandle);
begin
  FLock.Enter;
  try
    FHandle:=Value;
    UpdateSizes;
  finally
    FLock.Leave;
  end;
end;

procedure TDirectRender.SetHeight(const Value: integer);
begin
  FLock.Enter;
  try
    if FHeight<>Value then
    begin
      FHeight:=Value;
      UpdateSizes;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TDirectRender.SetSize(AWidth, AHeight: integer);
begin
  FLock.Enter;
  try
    if (FWidth<>AWidth)or(FHeight<>AHeight) then
    begin
      FHeight:=AHeight;
      FWidth:=AWidth;
      UpdateSizes;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TDirectRender.SetWidth(const Value: integer);
begin
  FLock.Enter;
  try
    if FWidth<>Value then
    begin
      FWidth:=Value;
      UpdateSizes;
    end;
  finally
    FLock.Leave;
  end;
end;

{$IFDEF FPC}
procedure TDirectRender.ClearData(AData: Pointer);
var
  DecodedFrame: PDecodedFrame;
begin
  DecodedFrame:=PDecodedFrame(AData);
  Dispose(DecodedFrame);
end;
{$ENDIF}

procedure TDirectRender.SkipSecond;
begin
  SkipThru:=IncSecond(now);
end;

procedure TDirectRender.UpdateScreen;
begin
  if assigned(FLastPicture) and (FLastPicture.Time>0) then
    Drawer.Draw(FLastPicture);
end;

procedure TDirectRender.UpdateSizes;
begin
  if assigned(FDrawer) then
    TDrawer(FDrawer).SetHandle(FHandle);
end;

end.
