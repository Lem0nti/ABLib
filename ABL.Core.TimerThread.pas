unit ABL.Core.TimerThread;

interface

uses
  ABL.Core.BaseThread, Classes, SysUtils, Types, SyncObjs, ABL.Core.BaseQueue, ABL.Core.Debug;

type
  TReceiveThread=class;

  TTimerThread=class(TBaseThread)
  private
    FReceiveCounter: Extended;
    ReceiveThread: TReceiveThread;
    function GetEnabled: boolean;
    function GetInterval: Cardinal;
    procedure SetEnabled(const Value: boolean);
    procedure SetInterval(const Value: Cardinal);
    procedure SetReceiveCounter(AValue: Extended);
    function GetReceiveCounter: Extended;
  protected
    FEnabled: boolean;
    FInterval: Cardinal;
    FWaitForStop: TEvent;
    procedure DoExecute; virtual; abstract;
    procedure DoReceive(var AInputData: Pointer); virtual; abstract;
    procedure Execute; override;
    procedure Run;
    procedure StopReceive;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); overload; override;
    constructor Create(AName: string = ''); overload; override;
    destructor Destroy; override;
    property Enabled: boolean read GetEnabled write SetEnabled;
    property Interval: Cardinal read GetInterval write SetInterval;
    property ReceiveCounter: Extended read GetReceiveCounter;
  end;

  TReceiveThread=class(TThread)
  private
    FTimerThread: TTimerThread;
  protected
    procedure Execute; override;
  public
    constructor Create(ATimerThread: TTimerThread); reintroduce;
  end;

implementation

{ TTimerThread }

constructor TTimerThread.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  ReceiveThread:=nil;
  FWaitForStop:=TEvent.Create(nil,True,False,'');
  FInterval:=1000;
  FEnabled:=true;
  Run;
end;

constructor TTimerThread.Create(AName: string);
begin
  inherited Create(AName);
  ReceiveThread:=nil;
  FWaitForStop:=TEvent.Create(nil,True,False,'');
  FInterval:=1000;
  FEnabled:=true;
  Run;
end;

destructor TTimerThread.Destroy;
begin
  StopReceive;
  Stop;
  FWaitForStop.SetEvent;
  FWaitForStop.Free;
  inherited;
end;

procedure TTimerThread.Execute;
var
  OldInterval: Cardinal;
  aStopped: TWaitResult;
begin
  try
    try
      while not Terminated do
      begin
        OldInterval:=Interval;
        aStopped:=FWaitForStop.WaitFor(OldInterval);
        if aStopped=wrTimeOut then
        begin
          if Enabled then
          begin
            StartWatch;
            DoExecute;
            IncreaseIteration(StopWatch);
            if Terminated then
              exit;
            FLastExec:=now;
          end;
        end
        else if FTerminated or (OldInterval=Interval) then  //мб было изменение интервала
          exit;
      end;
    except on e: Exception do
      if not FTerminated then
        SendErrorMsg('TTimerThread.Execute '+ClassName+'('+FName+') 109: '+e.ClassName+' - '+e.Message);
    end;
  finally
    SubThread:=nil;
  end;
end;

function TTimerThread.GetEnabled: boolean;
begin
  Lock;
  try
    result:=FEnabled;
  finally
    Unlock;
  end;
end;

function TTimerThread.GetInterval: Cardinal;
begin
  Lock;
  try
    result:=FInterval;
  finally
    Unlock;
  end;
end;

function TTimerThread.GetReceiveCounter: Extended;
begin
  Lock;
  try
    result:=FReceiveCounter;
  finally
    Unlock;
  end;
end;

procedure TTimerThread.Run;
begin
  if assigned(FInputQueue) and (not assigned(ReceiveThread)) then
    ReceiveThread:=TReceiveThread.Create(Self);
end;

procedure TTimerThread.SetEnabled(const Value: boolean);
begin
  Lock;
  try
    FEnabled:=Value;
  finally
    Unlock;
  end;
end;

procedure TTimerThread.SetInterval(const Value: Cardinal);
begin
  Lock;
  try
    if FInterval<>Value then
    begin
      FInterval:=Value;
      if assigned(SubThread) then
        FWaitForStop.SetEvent;
    end;
  finally
    Unlock;
  end;
end;

procedure TTimerThread.SetReceiveCounter(AValue: Extended);
begin
  Lock;
  try
    FReceiveCounter:=AValue;
  finally
    Unlock;
  end;
end;

procedure TTimerThread.StopReceive;
begin
  if assigned(ReceiveThread) then
    ReceiveThread.Terminate;
  ReceiveThread:=nil;
  if assigned(FInputQueue) then
    FInputQueue.SetEvent;
end;

{ TReceiveThread }

constructor TReceiveThread.Create(ATimerThread: TTimerThread);
begin
  inherited Create(false);
  FTimerThread:=ATimerThread;
  FreeOnTerminate:=true;
end;

procedure TReceiveThread.Execute;
var
  Mess: Pointer;
  ExitOnError: boolean;
  T3: int64;
  cnt: integer;
begin
  ExitOnError:=true;
  T3:=0;
  cnt:=0;
  while not Terminated do
    try
      ExitOnError:=true;
      if assigned(FTimerThread.FInputQueue) then
        FTimerThread.FInputQueue.WaitForItems(INFINITE)
      else
      begin
        SendErrorMsg('TReceiveThread.Execute '+FTimerThread.ClassName+'('+FTimerThread.FName+').Execute 219: не указана входящая очередь');
        FTimerThread.StopReceive;
      end;
      if (not Terminated)and assigned(FTimerThread.FInputQueue) then
        while FTimerThread.InputQueue.Count>0 do
        begin
          Mess:=FTimerThread.InputQueue.Pop;
          try
            ExitOnError:=false;
            FTimerThread.StartWatch;
            FTimerThread.DoReceive(Mess);
            T3:=T3+FTimerThread.StopWatch;
            inc(cnt);
            if cnt>=100 then
            begin
              FTimerThread.SetReceiveCounter(T3/100);
              T3:=0;
              cnt:=0;
            end;
            if Terminated then
              exit;
          finally
            if assigned(Mess) then
              FreeMem(Mess);
          end;
        end;
    except on e: Exception do
      begin
        SendErrorMsg('TReceiveThread.Execute '+FTimerThread.ClassName+'('+FTimerThread.FName+').Execute 251: '+e.ClassName+' - '+e.Message);
        if ExitOnError then
          FTimerThread.Stop;
      end;
    end;
end;

end.
