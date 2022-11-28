unit ABL.Core.ThreadController;

interface

uses
  ABL.Core.TimerThread, ABL.Core.BaseQueue, ABL.Core.BaseThread, ABL.Core.ThreadQueue, SysUtils,
  {$IFNDEF FPC}PsAPI,{$ENDIF}{$IFDEF MSWINDOWS}Windows,{$ENDIF} ABL.Core.Debug, SyncObjs, ABL.Core.ThreadItem;

type
  TThreadController=class(TTimerThread)
  private
    FLogMem: Cardinal;
    FLogPerformanceValue: Real;
    FLogQueueValue: Cardinal;
    function GetLogQueueValue: Cardinal;
    procedure SetLogQueueValue(const Value: Cardinal);
    function GetLogMem: Cardinal;
    procedure SetLogMem(const Value: Cardinal);
    function GetLogPerformanceValue: Real;
    procedure SetLogPerformanceValue(const Value: Real);
  protected
    procedure DoExecute; override;
    procedure DoReceive(var AInputData: Pointer); override;
  public
    constructor Create; reintroduce;
    function CheckForAllEmpty: boolean;
    function GetStructure: string;
    function ItemByName(AName: string): TThreadItem;
    function ThreadByName(AName: string): TBaseThread;
    function QueueByName(AName: string): TBaseQueue;
    property LogMem: Cardinal read GetLogMem write SetLogMem;
    property LogPerformanceValue: Real read GetLogPerformanceValue write SetLogPerformanceValue;
    property LogQueueValue: Cardinal read GetLogQueueValue write SetLogQueueValue;
  end;

var
  ThreadController: TThreadController;

implementation

{ TThreadController }

function TThreadController.CheckForAllEmpty: boolean;
var
  Queue: TBaseQueue;
begin
  Lock;
  try
    result:=true;
    for Queue in QueueList do
      if Queue.Count>0 then
      begin
        result:=false;
        exit;
      end;
  finally
    Unlock;
  end;
end;

constructor TThreadController.Create;
begin
  inherited Create(nil,nil);
  FLogQueueValue:=8;
  FLogMem:=128;
  FLogPerformanceValue:=32;
  FInterval:=20000;
  FEnabled:=true;
  Start;
end;

procedure TThreadController.DoExecute;
var
  tmpMem,CurMem: Cardinal;
  tmpPerformanceValue: Real;
  Queue: TBaseQueue;
  tmpName: string;
  cnt,tmpQueueValue: integer;
  perf: Real;
  Thread: TBaseThread;
  cb: integer;
  {$IFNDEF FPC}
  pmc: PPROCESS_MEMORY_COUNTERS;
  {$ENDIF}
begin
  Lock;
  tmpQueueValue:=FLogQueueValue;
  tmpMem:=FLogMem;
  tmpPerformanceValue:=FLogPerformanceValue;
  Unlock;
  for Queue in QueueList do
  begin
    cnt:=Queue.Count;
    if cnt>tmpQueueValue then
    begin
      tmpName:=Queue.Name;
      if tmpName<>'' then
        SendPerformanceMsg('TThreadController.DoExecute 97, '+tmpName+'='+IntToStr(cnt));
    end;
  end;
  for Thread in ThreadList do
  begin
    perf:=Thread.Performance;
    if perf>tmpPerformanceValue then
    begin
      tmpName:=Thread.Name;
      if tmpName<>'' then
        SendPerformanceMsg('TThreadController.DoExecute 107, '+tmpName+'='+FormatFloat('0.0000',perf)+', '+IntToStr(Thread.IterationCount));
    end;
  end;
  {$IFNDEF FPC}
  cb:=SizeOf(_PROCESS_MEMORY_COUNTERS);
  GetMem(pmc,cb);
  try
    pmc^.cb:=cb;
    if GetProcessMemoryInfo(GetCurrentProcess,pmc,cb) then
    begin
      CurMem:=pmc^.WorkingSetSize div (1024*1024);
      if CurMem>tmpMem then
        SendPerformanceMsg('TThreadController.DoExecute 119, использование ОЗУ: '+IntToStr(CurMem)+' Mb');
    end;
  finally
    FreeMem(pmc);
  end;
  {$ENDIF}
end;

procedure TThreadController.DoReceive(var AInputData: Pointer);
begin

end;

function TThreadController.GetLogMem: Cardinal;
begin
  Lock;
  try
    result:=FLogMem;
  finally
    Unlock;
  end;
end;

function TThreadController.GetLogPerformanceValue: Real;
begin
  Lock;
  try
    result:=FLogPerformanceValue;
  finally
    Unlock;
  end;
end;

function TThreadController.GetLogQueueValue: Cardinal;
begin
  Lock;
  try
    result:=FLogQueueValue;
  finally
    Unlock;
  end;
end;

function TThreadController.GetStructure: string;
var
  tmpQueue: TBaseQueue;
  tmpThread: TBaseThread;
begin
  result:='[TBaseQueue]'#13#10;
  FLock.Enter;
  try
    for tmpQueue in QueueList do
      result:=result+tmpQueue.ClassName+' '+tmpQueue.Name+' '+IntToStr(tmpQueue.ID)+#13#10;
    result:=result+'[TBaseThread]'#13#10;
    for tmpThread in ThreadList do
      if tmpThread<>Self then
      begin
        result:=result+tmpThread.ClassName+' '+tmpThread.Name+' '+IntToStr(tmpThread.ID)+' ';
        tmpQueue:=tmpThread.InputQueue;
        if assigned(tmpQueue) then
          result:=result+IntToStr(tmpQueue.ID)
        else
            result:=result+'0';
        result:=result+' ';
        tmpQueue:=tmpThread.OutputQueue;
        if assigned(tmpQueue) then
          result:=result+IntToStr(tmpQueue.ID)
        else
          result:=result+'0';
        result:=result+#13#10;
      end;
  finally
    FLock.Leave;
  end;
end;

function TThreadController.ItemByName(AName: string): TThreadItem;
begin

end;

function TThreadController.QueueByName(AName: string): TBaseQueue;
var
  Queue: TBaseQueue;
begin
  for Queue in QueueList do
    if Queue.Name=AName then
    begin
      result:=Queue;
      exit;
    end;
  Queue:=TThreadQueue.Create(AName);
  result:=Queue;
end;

procedure TThreadController.SetLogMem(const Value: Cardinal);
begin
  FLock.Enter;
  try
    FLogMem:=Value;
  finally
    FLock.Leave;
  end;
end;

procedure TThreadController.SetLogPerformanceValue(const Value: Real);
begin
  FLock.Enter;
  try
    FLogPerformanceValue:=Value;
  finally
    FLock.Leave;
  end;
end;

procedure TThreadController.SetLogQueueValue(const Value: Cardinal);
begin
  FLock.Enter;
  try
    FLogQueueValue:=Value;
  finally
    FLock.Leave;
  end;
end;

function TThreadController.ThreadByName(AName: string): TBaseThread;
var
  Thread: TBaseThread;
begin
  FLock.Enter;
  try
    result:=nil;
    for Thread in ThreadList do
      if Thread.Name=AName then
      begin
        result:=Thread;
        exit;
      end;
  finally
    FLock.Leave;
  end;
end;

initialization
  ThreadController:=TThreadController.Create;

finalization
  ThreadController.Free;

end.
