unit ABL.Core.ThreadQueue;

interface

uses
  ABL.Core.BaseQueue, SysUtils, Contnrs, SyncObjs;

type
  TThreadQueue=class(TBaseQueue)
  public
    procedure Clear; override;
    function Pop: Pointer; override;
    procedure Push(AItem: Pointer); override;
  end;

implementation

{ TThreadQueue }

procedure TThreadQueue.Clear;
var
  tmpData: Pointer;
begin
  FLock.Enter;
  try
    while Count>0 do
    begin
      tmpData:=Queue.Pop;
      FreeMem(tmpData);
    end;
    FWaitItemsEvent.ResetEvent;
    FWaitEmptyItems.SetEvent;
  finally
    FLock.Leave;
  end;
end;

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
