unit ABL.Core.ThreadQueue;

interface

uses
  ABL.Core.BaseQueue, SysUtils, Contnrs, SyncObjs;

type
  TThreadQueue=class(TBaseQueue)
  public
    function Pop: Pointer; override;
    procedure Push(AItem: Pointer); override;
  end;

implementation

{ TThreadQueue }

function TThreadQueue.Pop: Pointer;
begin
  FLock.Enter;
  try
    Result:=Queue.Pop;
    if Count=0 then
    begin
      FWaitItemsEvent.ResetEvent;
      FWaitEmptyItems.SetEvent;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TThreadQueue.Push(AItem: Pointer);
begin
  FLock.Enter;
  try
    Queue.Push(AItem);
    FWaitItemsEvent.SetEvent;
    FWaitEmptyItems.ResetEvent;
    FLastInput:=now;
  finally
    FLock.Leave;
  end;
end;

end.
