unit ABL.Render.DirectRender;

interface

uses
  ABL.Core.DirectThread, ABL.Render.Drawer, ABL.VS.VSTypes, SysUtils,
  SyncObjs, ABL.Core.ThreadItem,
  DateUtils;

type

  { TDirectRender }

  TDirectRender=class(TDirectThread)
  private
    FDrawer: TDrawer;
    FLastPicture,OldData: PImageDataHeader;
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
    function LastPicture(Original: boolean = false): PImageDataHeader;
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
  SkipThru:=0;
  FLastPicture:=nil;
  Active:=true;
  GetMem(FLastPicture,3000*2048*3);
  FPaused:=false;
  GetMem(OldData,3000*2048*3);
end;

destructor TDirectRender.Destroy;
begin
  if assigned(FDrawer) then
    FreeAndNil(FDrawer);
  FreeMem(FLastPicture);
  inherited;
end;

procedure TDirectRender.DoExecute(var AInputData: Pointer;
  var AResultData: Pointer);
var
  rData: PImageDataHeader;
  DrawResult: integer;
begin
  rData:=AInputData;
  if (SkipThru<now) and assigned(FDrawer) then
  begin
    if not FPaused then
    begin
      OldData.Width:=rData.Width;
      OldData.Height:=rData.Height;
      OldData.TimedDataHeader.Time:=rData.TimedDataHeader.Time;
      Move(rData^,OldData^,rData.TimedDataHeader.DataHeader.Size);
      DrawResult:=FDrawer.Draw(rData);
      Move(rData.Data^,FLastPicture.Data^,rData.Width*rData.Height*3);
      FLastPicture.Width:=rData.Width;
      FLastPicture.Height:=rData.Height;
      FLastPicture.TimedDataHeader.Time:=rData.TimedDataHeader.Time;
      if DrawResult<0 then
        SkipSecond;
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

function TDirectRender.LastPicture(Original: boolean = false): PImageDataHeader;
var
  DecodedFrame: PImageDataHeader;
  sz: Cardinal;
begin
  result:=nil;
  FLock.Enter;
  try
    if Original then
      DecodedFrame:=OldData
    else
      DecodedFrame:=FLastPicture;
    if assigned(DecodedFrame) then
    begin
      sz:=DecodedFrame.TimedDataHeader.DataHeader.Size;
      if sz>0 then
      begin
        GetMem(result,sz);
        Move(DecodedFrame^,result^,sz);
      end;
    end;
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

procedure TDirectRender.SkipSecond;
begin
  SkipThru:=IncSecond(now);
end;

procedure TDirectRender.UpdateScreen;
begin
  if assigned(FLastPicture) and (FLastPicture.TimedDataHeader.Time>0) then
    Drawer.Draw(FLastPicture);
end;

procedure TDirectRender.UpdateSizes;
begin
  if assigned(FDrawer) then
    TDrawer(FDrawer).SetHandle(FHandle);
end;

end.
