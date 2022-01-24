unit ABL.Render.Drawer;

interface

uses
  ABL.Core.BaseObject, ABL.VS.VSTypes, SyncObjs;

type
  TDrawer=class(TBaseObject)
  private
    function GetShowTime: boolean;
    procedure SetShowTime(const Value: boolean);
    function GetVerticalMirror: boolean;
    procedure SetVerticalMirror(const Value: boolean);
  protected
    FShowTime: boolean;
    FVerticalMirror: boolean;
  public
    function Draw(ADecodedFrame: PDecodedFrame): integer; virtual; abstract;
    property VerticalMirror: boolean read GetVerticalMirror write SetVerticalMirror;
    property ShowTime: boolean read GetShowTime write SetShowTime;
  end;

implementation

{ TDrawer }

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
