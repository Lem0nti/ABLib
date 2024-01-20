unit ABL.Core.ThreadItem;

interface

uses
  ABL.Core.BaseQueue, SyncObjs;

type
  TThreadItem=class(TBaseQueue)
  protected
    PMain: Pointer;
  public
    constructor Create(AName: string = ''); override;
    procedure Clear; override;
    function Count: Integer; override;
    function Pop: Pointer; override;
    procedure Push(AItem: Pointer); override;
  end;

implementation

{ TThreadItem }

procedure TThreadItem.Clear;
begin
  FLock.Enter;
  try
    if assigned(PMain) then
    begin
      FreeMem(PMain);
      PMain:=nil;
      FWaitEmptyItems.SetEvent;
      FWaitItemsEvent.ResetEvent;
    end;
  finally
    FLock.Leave;
  end;
end;

function TThreadItem.Count: Integer;
begin
  FLock.Enter;
  try
    if assigned(PMain) then
      result:=1
    else
      result:=0;
  finally
    FLock.Leave;
  end;
end;

constructor TThreadItem.Create(AName: string);
begin
  inherited Create(AName);
  PMain:=nil;
end;

function TThreadItem.Pop: Pointer;
begin
  FLock.Enter;
  try
    result:=PMain;
    PMain:=nil;
    FWaitEmptyItems.SetEvent;
    FWaitItemsEvent.ResetEvent;
  finally
    FLock.Leave;
  end;
end;

procedure TThreadItem.Push(AItem: Pointer);
begin
  FLock.Enter;
  try
    if assigned(PMain) then
      Freemem(PMain);
    PMain:=AItem;
    FWaitEmptyItems.ResetEvent;
    FWaitItemsEvent.SetEvent;
  finally
    FLock.Leave;
  end;
end;

end.
