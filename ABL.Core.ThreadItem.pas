unit ABL.Core.ThreadItem;

interface

uses
  ABL.Core.BaseQueue;

type
  TThreadItem=class(TBaseQueue)
  protected
    PMain: Pointer;
  public
    constructor Create(AName: string = ''); override;
    function Count: Integer; override;
    function Pop: Pointer; override;
    procedure Push(AItem: Pointer); override;
  end;

implementation

{ TThreadItem }

function TThreadItem.Count: Integer;
begin
  Lock;
  try
    if assigned(PMain) then
      result:=1
    else
      result:=0;
  finally
    Unlock;
  end;
end;

constructor TThreadItem.Create(AName: string);
begin
  inherited Create(AName);
  PMain:=nil;
end;

function TThreadItem.Pop: Pointer;
begin
  Lock;
  try
    result:=PMain;
    PMain:=nil;
    FWaitEmptyItems.SetEvent;
    FWaitItemsEvent.ResetEvent;
  finally
    Unlock;
  end;
end;

procedure TThreadItem.Push(AItem: Pointer);
begin
  Lock;
  try
    if assigned(PMain) then
      Freemem(PMain);
    PMain:=AItem;
    FWaitEmptyItems.ResetEvent;
    FWaitItemsEvent.SetEvent;
  finally
    Unlock;
  end;
end;

end.
