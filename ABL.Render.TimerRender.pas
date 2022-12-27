unit ABL.Render.TimerRender;

interface

uses
  ABL.Core.TimerThread, ABL.Render.Drawer, ABL.VS.VSTypes, ABL.Core.BaseQueue, SysUtils;

type

  { TTimerRender }

  TTimerRender=class(TTimerThread)
  private
    FHandle: THandle;
    function GetHandle: THandle;
    procedure SetHandle(const Value: THandle);
    function GetHeight: Word;
    function GetWidth: Word;
    procedure SetHeight(const Value: Word);
    procedure SetWidth(const Value: Word);
    function GetOnDraw: TDrawNotify;
    procedure SetOnDraw(const Value: TDrawNotify);
  protected
    FDrawer: TDrawer;
    FPicture: Pointer;
    procedure DoExecute; override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    destructor Destroy; override;
    procedure SetSize(AWidth,AHeight: Word);
    procedure UpdateSizes;
    property Handle: THandle read GetHandle write SetHandle;
    property Height: Word read GetHeight write SetHeight;
    property OnDraw: TDrawNotify read GetOnDraw write SetOnDraw;
    property Width: Word read GetWidth write SetWidth;
  end;

implementation

{ TTimerRender }

constructor TTimerRender.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
var
  ImageDataHeader: PImageDataHeader;
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  FDrawer:=TDrawer.Create(ClassName+'_'+AName+'_Drawer_'+IntToStr(FID));
  GetMem(FPicture,SizeOf(TImageDataHeader)+8);
  FHandle=0;
  SetSize(1920,1080);
  FInterval=0;
end;

destructor TTimerRender.Destroy;
begin
  FTerminated:=true;
  Enabled:=false;
  FDrawer.Free;
  inherited Destroy;
end;

procedure TTimerRender.DoExecute;
begin
  FLock.Enter;
  try
    if (not Terminated) and (FDrawer.Draw(FPicture)<0) then
      FTerminated:=true;
  finally
    FLock.Leave;
  end;
end;

function TTimerRender.GetHandle: THandle;
begin
  FLock.Enter;
  try
    result:=FHandle;
  finally
    FLock.Leave;
  end;
end;

function TTimerRender.GetHeight: Word;
begin
  FLock.Enter;
  try
    result:=PImageDataHEader(FPicture).Height;
  finally
    FLock.Leave;
  end;
end;

function TTimerRender.GetOnDraw: TDrawNotify;
begin
  result:=FDrawer.OnDraw;
end;

function TTimerRender.GetWidth: Word;
begin
  FLock.Enter;
  try
    result:=PImageDataHEader(FPicture).Width;
  finally
    FLock.Leave;
  end;
end;

procedure TTimerRender.SetHandle(const Value: THandle);
begin
  FLock.Enter;
  try
    FHandle:=Value;
    UpdateSizes;
  finally
    FLock.Leave;
  end;
end;

procedure TTimerRender.SetHeight(const Value: Word);
begin
  FLock.Enter;
  try
    PImageDataHEader(FPicture).Height:=Value;
    UpdateSizes;
  finally
    FLock.Leave;
  end;
end;

procedure TTimerRender.SetOnDraw(const Value: TDrawNotify);
begin
  FDrawer.OnDraw:=Value;
end;

procedure TTimerRender.SetSize(AWidth, AHeight: Word);
begin
  FLock.Enter;
  try
    PImageDataHEader(FPicture).Width:=AWidth;
    PImageDataHEader(FPicture).Height:=AHeight;
    UpdateSizes;
  finally
    FLock.Leave;
  end;
end;

procedure TTimerRender.SetWidth(const Value: Word);
begin
  FLock.Enter;
  try
    PImageDataHEader(FPicture).Width:=Value;
    UpdateSizes;
  finally
    FLock.Leave;
  end;
end;

procedure TTimerRender.UpdateSizes;
var
  ImageDataHeader: PImageDataHeader;
  tmpDataSize: integer;
  tmpWidth,tmpHeight: Word;
begin
  tmpWidth:=ImageDataHeader.Width;
  tmpHeight:=ImageDataHeader.Height;
  tmpDataSize:=SizeOf(TImageDataHeader)+tmpWidth*tmpHeight*3;
  FPicture=ReallocMemory(FPicture,tmpDataSize);
  ImageDataHeader:=FPicture;
  ImageDataHeader.TimedDataHeader.DataHeader.Magic:=16961;
  ImageDataHeader.TimedDataHeader.DataHeader.Version=0;
  ImageDataHeader.TimedDataHeader.DataHeader.DataType=2;
  ImageDataHeader.TimedDataHeader.DataHeader.Size=tmpDataSize;
  ImageDataHeader.Left:=0;
  ImageDataHeader.Top:=0;
  ImageDataHeader.ImageType:=itBGR;
  ImageDataHeader.FlipMarker:=false;
end;

end.
