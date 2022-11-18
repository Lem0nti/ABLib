unit ABL.Render.DirectRender;

interface

uses
  ABL.Core.DirectThread, ABL.Render.Drawer, ABL.VS.VSTypes, SysUtils,
  SyncObjs, ABL.Core.ThreadItem,
  DateUtils, ABL.Core.Debug;

type

  { TDirectRender }

  TDirectRender=class(TDirectThread)
  private
    FDrawer: TDrawer;
    FLastPicture,OldData: PDecodedFrame;
    SkipThru: TDateTime;
    FHandle: THandle;
    FPaused: boolean;
    procedure UpdateSizes;
    function GetHandle: THandle;
    procedure SetHandle(const Value: THandle);
    function GetCameraName: string;
    procedure SetCameraName(const Value: string);
    function GetOnDraw: TDrawNotify;
    procedure SetOnDraw(const Value: TDrawNotify);
    function GetPaused: boolean;
    procedure SetPaused(const Value: boolean);
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AName: string = ''); override;
    destructor Destroy; override;
    function LastPicture(Original: boolean = false): PDecodedFrame;
    procedure SkipSecond;
    procedure UpdateScreen;
    property CameraName: string read GetCameraName write SetCameraName;
    property Drawer: TDrawer read FDrawer;
    property Handle: THandle read GetHandle write SetHandle;
    property OnDraw: TDrawNotify read GetOnDraw write SetOnDraw;
    property Paused: boolean read GetPaused write SetPaused;
  end;

implementation

{ TDirectRender }

constructor TDirectRender.Create(AName: string);
begin
  inherited Create(nil,nil,AName);
  FInputQueue:=TThreadItem.Create(ClassName+'_'+AName+'_Input_'+IntToStr(FID));
  FDrawer:=TDrawer.Create(0,ClassName+'_'+AName+'_Drawer_'+IntToStr(FID));
//  FWidth:=1920;
//  FHeight:=1080;
  SkipThru:=0;
  FLastPicture:=nil;
  Active:=true;
  new(FLastPicture);
  FLastPicture.Time:=0;
  GetMem(FLastPicture.Data,3000*2000*3);
  FPaused:=false;
  new(OldData);
  GetMem(OldData.Data,3000*2000*3);
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
  DrawResult:=-2;
  rData:=PDecodedFrame(AInputData);
  try
    if (SkipThru<now) and assigned(FDrawer) then
    begin
      if not FPaused then
      begin
        OldData.Width:=rData.Width;
        OldData.Height:=rData.Height;
        OldData.Time:=rData.Time;
        Move(rData.Data^,OldData.Data^,rData.Width*rData.Height*3);
        DrawResult:=FDrawer.Draw(rData);
        Move(rData.Data^,FLastPicture.Data^,rData.Width*rData.Height*3);
        FLastPicture.Width:=rData.Width;
        FLastPicture.Height:=rData.Height;
        FLastPicture.Time:=rData.Time;
        if DrawResult<0 then
          SkipSecond;
      end;
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

//function TDirectRender.GetHeight: integer;
//begin
//  FLock.Enter;
//  try
//    result:=FHeight;
//  finally
//    FLock.Leave;
//  end;
//end;

function TDirectRender.GetOnDraw: TDrawNotify;
begin
  result:=FDrawer.OnDraw;
end;

function TDirectRender.GetPaused: boolean;
begin
  FLock.Enter;
  try
    result:=FPaused;
  finally
    FLock.Leave;
  end;
end;

//function TDirectRender.GetWidth: integer;
//begin
//  FLock.Enter;
//  try
//    result:=FWidth;
//  finally
//    FLock.Leave;
//  end;
//end;

function TDirectRender.LastPicture(Original: boolean = false): PDecodedFrame;
var
  DecodedFrame: PDecodedFrame;
begin
  result:=nil;
  if Original then
    DecodedFrame:=OldData
  else
    DecodedFrame:=FLastPicture;
  if assigned(DecodedFrame) then
  begin
    New(result);
    FLock.Enter;
    try
      result.Time:=DecodedFrame.Time;
      result.Width:=DecodedFrame.Width;
      result.Height:=DecodedFrame.Height;
      result.Left:=DecodedFrame.Left;
      result.Top:=DecodedFrame.Top;
      result.ImageType:=DecodedFrame.ImageType;
      GetMem(result.Data,result.Width*result.Height*3);
      Move(DecodedFrame.Data^,result.Data^,result.Width*result.Height*3);
    finally
      FLock.Leave;
    end;
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

//procedure TDirectRender.SetHeight(const Value: integer);
//begin
//  FLock.Enter;
//  try
//    if FHeight<>Value then
//    begin
//      FHeight:=Value;
//      UpdateSizes;
//    end;
//  finally
//    FLock.Leave;
//  end;
//end;

procedure TDirectRender.SetOnDraw(const Value: TDrawNotify);
begin
  FDrawer.OnDraw:=Value;
end;

procedure TDirectRender.SetPaused(const Value: boolean);
begin
  FLock.Enter;
  try
    FPaused:=Value;
  finally
    FLock.Leave;
  end;
end;

//procedure TDirectRender.SetSize(AWidth, AHeight: integer);
//begin
//  FLock.Enter;
//  try
//    if (FWidth<>AWidth)or(FHeight<>AHeight) then
//    begin
//      FHeight:=AHeight;
//      FWidth:=AWidth;
//      UpdateSizes;
//    end;
//  finally
//    FLock.Leave;
//  end;
//end;

//procedure TDirectRender.SetWidth(const Value: integer);
//begin
//  FLock.Enter;
//  try
//    if FWidth<>Value then
//    begin
//      FWidth:=Value;
//      UpdateSizes;
//    end;
//  finally
//    FLock.Leave;
//  end;
//end;

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
