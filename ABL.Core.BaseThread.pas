unit ABL.Core.BaseThread;

interface

uses
  ABL.Core.BaseObject, ABL.Core.BaseQueue, ABL.Core.ThreadQueue, Classes, SysUtils,
  {$IFDEF UNIX}fgl, linux, unixtype{$ELSE}Generics.Collections, Windows{$ENDIF};

type
  TSubThread=class;

  TBaseThread=class(TBaseObject)
  private
    FStartTimeStamp: int64;
    function GetLastExec: TDateTime;
    function GetPerformance: Real;
    function GetActive: boolean;
    procedure SetActive(const Value: boolean);
  protected
    FTerminated: boolean;
    SubThread: TSubThread;
    FPerformance: Real;
    FLastExec: TDateTime;
    FInputQueue, FOutputQueue: TBaseQueue;
    iCounterPerMSec, Time100: int64;
    {$IFDEF FPC}
    procedure ClearData(AData: Pointer); virtual; abstract;
    {$ENDIF}
    procedure IncreaseIteration(ATime: int64);
    procedure Execute; virtual; abstract;
    procedure Start; virtual;
    procedure StartWatch;
    function StopWatch: int64;
    function Terminated: boolean;
  public
    FIterationCounter: Cardinal;
    constructor Create(AName: string = ''); overload; override;
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); reintroduce; overload; virtual;
    destructor Destroy; override;
    function InputQueue: TBaseQueue; virtual;
    function OutputQueue: TBaseQueue; virtual;
    procedure SetInputQueue(Queue: TBaseQueue); virtual;
    procedure SetOutputQueue(Queue: TBaseQueue); virtual;
    procedure Stop; virtual;
    property Active: boolean read GetActive write SetActive;
    property LastExec: TDateTime read GetLastExec;
    property Performance: Real read GetPerformance;
  end;

  TSubThread=class(TThread)
  private
    FBaseThread: TBaseThread;
  protected
    procedure Execute; override;
  public
    constructor Create(ABaseThread: TBaseThread); reintroduce;
  end;

  {$IFDEF FPC}
  TBaseThreadList = specialize {$IFDEF UNIX}TFPGObjectList{$ELSE}TObjectList{$ENDIF}<TBaseThread>;
  {$ENDIF}

var
  ThreadList: {$IFDEF FPC}TBaseThreadList{$ELSE}TObjectList<TBaseThread>{$ENDIF};

implementation

{ TBaseThread }

constructor TBaseThread.Create(AName: string);
begin
  Create(nil,nil,AName);
  FInputQueue:=TThreadQueue.Create(ClassName+'_'+AName+'_Input_'+IntToStr(FID));
end;

constructor TBaseThread.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AName);
  FTerminated:=true;
  FInputQueue:=AInputQueue;
  FOutputQueue:=AOutputQueue;
  FIterationCounter:=0;
  {$IFDEF MSWINDOWS}
  if not QueryPerformanceFrequency(iCounterPerMSec) then
  {$ENDIF}
    iCounterPerMSec:=10000000;
  iCounterPerMSec:=Round(iCounterPerMSec/1000);
  ThreadList.Add(Self);
end;

destructor TBaseThread.Destroy;
begin
  ThreadList.Remove(Self);
  Stop;
  inherited;
end;

function TBaseThread.GetActive: boolean;
begin
  result:=assigned(SubThread);
end;

function TBaseThread.GetLastExec: TDateTime;
begin
  Lock;
  try
    result:=FLastExec;
  finally
    Unlock;
  end;
end;

function TBaseThread.GetPerformance: Real;
begin
  Lock;
  try
    result:=FPerformance;
  finally
    Unlock;
  end;
end;

procedure TBaseThread.IncreaseIteration(ATime: int64);
begin
  Time100:=Time100+ATime;
  inc(FIterationCounter);
  if FIterationCounter div 100=FIterationCounter/100 then
  begin
    FPerformance:=(Time100/100)/iCounterPerMSec;
    Time100:=0;
  end;
end;

function TBaseThread.InputQueue: TBaseQueue;
begin
  result:=FInputQueue
end;

function TBaseThread.OutputQueue: TBaseQueue;
begin
  result:=FOutputQueue;
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

initialization
  ThreadList:={$IFDEF FPC}TBaseThreadList{$ELSE}TObjectList<TBaseThread>{$ENDIF}.Create;
  ThreadList.{$IFDEF UNIX}FreeObjects{$ELSE}OwnsObjects{$ENDIF}:=false;

finalization
  ThreadList.Free;

end.
