unit ABL.Core.BaseThread;

interface

uses
  ABL.Core.BaseHandler, ABL.Core.BaseQueue, ABL.Core.ThreadQueue, Classes, SysUtils,
  {$IFDEF UNIX}fgl, linux, unixtype{$ELSE}Generics.Collections, Windows{$ENDIF}, SyncObjs;

type
  TSubThread=class;

  TBaseThread=class(TBaseHandler)
  private
    FStartTimeStamp: int64;
    FThreadID: integer;
    function GetLastExec: TDateTime;
    function GetPerformance: Real;
    function GetActive: boolean;
    procedure SetActive(const Value: boolean);
    function GetIterationCount: Cardinal;
    function GetThreadID: integer;
  protected
    FIterationCounter: Cardinal;
    FTerminated: boolean;
    SubThread: TSubThread;
    FPerformance: Real;
    FLastExec: TDateTime;
    FInputQueue, FOutputQueue: TBaseQueue;
    iCounterPerMSec, Time100: int64;
    FBaseThreadLock: TCriticalSection;
    procedure IncreaseIteration(ATime: int64);
    procedure Execute; virtual; abstract;
    procedure Start; virtual;
    procedure StartWatch;
    function StopWatch: int64;
    function Terminated: boolean;
  public
    constructor Create(AName: string = ''); overload; override;
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); reintroduce; overload; virtual;
    destructor Destroy; override;
    function InputQueue: TBaseQueue; reintroduce;
    function OutputQueue: TBaseQueue; reintroduce;
    function Push(AItem: Pointer): boolean;
    procedure SetInputQueue(Queue: TBaseQueue); virtual;
    procedure SetOutputQueue(Queue: TBaseQueue); virtual;
    procedure Stop; virtual;
    property Active: boolean read GetActive write SetActive;
    property IterationCount: Cardinal read GetIterationCount;
    property LastExec: TDateTime read GetLastExec;
    property Performance: Real read GetPerformance;
    property ThreadID: integer read GetThreadID;
  end;

  TSubThread=class(TThread)
  private
    FBaseThread: TBaseThread;
  protected
    procedure Execute; override;
  public
    constructor Create(ABaseThread: TBaseThread); reintroduce;
  end;

implementation

{ TBaseThread }

constructor TBaseThread.Create(AName: string);
begin
  Create(TThreadQueue.Create(ClassName+'_'+AName+'_Input_'+IntToStr(FID)),nil,AName);
end;

constructor TBaseThread.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AName);
  FTerminated:=false;
  FInputQueue:=AInputQueue;
  FOutputQueue:=AOutputQueue;
  if assigned(AInputQueue) then
    FInputPin.Add(AInputQueue);
  if assigned(AOutputQueue) then
    FOutputPin.Add(AOutputQueue);
  FIterationCounter:=0;
  {$IFDEF MSWINDOWS}
  if not QueryPerformanceFrequency(iCounterPerMSec) then
  {$ENDIF}
    iCounterPerMSec:=10000000;
  iCounterPerMSec:=Round(iCounterPerMSec/1000);
end;

destructor TBaseThread.Destroy;
begin
  Stop;
  inherited;
end;

function TBaseThread.GetActive: boolean;
begin
  result:=assigned(SubThread);
end;

function TBaseThread.GetIterationCount: Cardinal;
begin
  FBaseThreadLock.Enter;
  try
    Result:=FIterationCounter;
  finally
    FBaseThreadLock.Leave;
  end;
end;

function TBaseThread.GetLastExec: TDateTime;
begin
  FBaseThreadLock.Enter;
  try
    result:=FLastExec;
  finally
    FBaseThreadLock.Leave;
  end;
end;

function TBaseThread.GetPerformance: Real;
begin
  FBaseThreadLock.Enter;
  try
    result:=FPerformance;
  finally
    FBaseThreadLock.Leave;
  end;
end;

function TBaseThread.GetThreadID: integer;
begin
  if assigned(SubThread) then
    Result:=SubThread.ThreadID
  else
    Result:=0;
end;

procedure TBaseThread.IncreaseIteration(ATime: int64);
begin
  Time100:=Time100+ATime;
  inc(FIterationCounter);
  if FIterationCounter mod 30=0 then
  begin
    FPerformance:=(Time100/30)/iCounterPerMSec;
    Time100:=0;
  end;
end;

function TBaseThread.InputQueue: TBaseQueue;
begin
  result:=FInputQueue;
end;

function TBaseThread.OutputQueue: TBaseQueue;
begin
  result:=FOutputQueue;
end;

function TBaseThread.Push(AItem: Pointer): boolean;
begin
  if assigned(FInputQueue) then
  begin
      FInputQueue.Push(AItem);
      result:=true;
  end
  else
    result:=false;
end;

procedure TBaseThread.SetActive(const Value: boolean);
begin
  if Value then
    Start
  else if (not Value) and assigned(SubThread) then
    Stop;
end;

procedure TBaseThread.SetInputQueue(Queue: TBaseQueue);
begin
  FInputQueue:=Queue;
end;

procedure TBaseThread.SetOutputQueue(Queue: TBaseQueue);
begin
  FOutputQueue:=Queue;
end;

procedure TBaseThread.Start;
begin
  FTerminated:=false;
  if not assigned(SubThread) then
    SubThread:=TSubThread.Create(Self);
end;

procedure TBaseThread.StartWatch;
{$IFDEF UNIX}
var
  res: timespec;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  QueryPerformanceCounter(FStartTimeStamp);
  {$ELSE}
  clock_gettime(CLOCK_MONOTONIC, @res);
  FStartTimeStamp := (Int64(1000000000) * res.tv_sec + res.tv_nsec) div 100;
  {$ENDIF}
end;

procedure TBaseThread.Stop;
begin
  FTerminated:=true;
  if assigned(SubThread) then
  begin
    if not SubThread.Terminated then
      SubThread.Terminate;
    SubThread:=nil;
  end;
  if assigned(FInputQueue) then
    FInputQueue.SetEvent;
end;

function TBaseThread.StopWatch: int64;
{$IFNDEF MSWINDOWS}
var
  res: timespec;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  QueryPerformanceCounter(result);
  {$ELSE}
  clock_gettime(CLOCK_MONOTONIC, @res);
  result:= (Int64(1000000000)*res.tv_sec+res.tv_nsec) div 100;
  {$ENDIF}
  result:=result-FStartTimeStamp;
end;

function TBaseThread.Terminated: boolean;
begin
  result:=FTerminated;
end;

{ TSubThread }

constructor TSubThread.Create(ABaseThread: TBaseThread);
begin
  inherited Create(false);
  FBaseThread:=ABaseThread;
  FreeOnTerminate:=true;
end;

procedure TSubThread.Execute;
begin
  FBaseThread.Execute;
end;

end.
