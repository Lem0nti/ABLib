unit ABL.Render.Drawer;

interface

uses
  ABL.Core.BaseObject, ABL.VS.VSTypes, SyncObjs, Types, ABL.Core.Debug, SysUtils;

type
  TDrawer=class(TBaseObject)
  private
    function GetShowTime: boolean;
    procedure SetShowTime(const Value: boolean);
    function GetVerticalMirror: boolean;
    procedure SetVerticalMirror(const Value: boolean);
    function GetFocusRect: TRect;
    procedure SetFocusRect(const Value: TRect);
  protected
    FFocusRect: TRect;
    FShowTime: boolean;
    FVerticalMirror: boolean;
  public
    function Draw(ADecodedFrame: PDecodedFrame): integer; virtual; abstract;
    property VerticalMirror: boolean read GetVerticalMirror write SetVerticalMirror;
    property ShowTime: boolean read GetShowTime write SetShowTime;
    property FocusRect: TRect read GetFocusRect write SetFocusRect;
  end;

implementation

{ TDrawer }

function TDrawer.GetFocusRect: TRect;
begin
  FLock.Enter;
  try
    result:=FFocusRect;
  finally
    FLock.Leave;
  end;
end;

function TDrawer.GetShowTime: boolean;
begin
  FLock.Enter;
  try
    result:=FShowTime;
  finally
    FLock.Leave;
  end;
end;

function TDrawer.GetVerticalMirror: boolean;
begin
  FLock.Enter;
  try
    result:=FVerticalMirror;
  finally
    FLock.Leave;
  end;
end;

procedure TDrawer.SetFocusRect(const Value: TRect);
begin
  FLock.Enter;
  try
    FFocusRect:=Value;
  finally
    FLock.Leave;
  end;
end;

procedure TDrawer.SetShowTime(const Value: boolean);
begin
  FLock.Enter;
  try
    FShowTime:=Value;
  finally
    FLock.Leave;
  end;
end;

procedure TDrawer.SetVerticalMirror(const Value: boolean);
begin
  FLock.Enter;
  try
    FVerticalMirror:=Value;
  finally
    FLock.Leave;
  end;
end;

end.
