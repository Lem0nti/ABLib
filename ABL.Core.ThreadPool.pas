unit ABL.Core.ThreadPool;

interface

uses
  ABL.Core.BaseHandler, ABL.Core.BaseQueue, ABL.Core.DirectThread, ABL.Core.QueueSplitter, SysUtils,
  {$IFDEF UNIX}fgl, linux, unixtype{$ELSE}Generics.Collections, Windows{$ENDIF}, ABL.Core.Debug;

type
  {$IFDEF FPC}
  TDirectThreadList = specialize {$IFDEF UNIX}TFPGObjectList{$ELSE}TObjectList{$ENDIF}<TDirectThread>;
  {$ENDIF}

  TThreadPool=class(TBaseHandler)
  private
    FQueueSplitter: TQueueSplitter;
    FAllThread: {$IFDEF FPC}TDirectThreadList{$ELSE}TObjectList<TDirectThread>{$ENDIF};
    function GetThreadCount: Cardinal;
    procedure SetThreadCount(const Value: Cardinal);
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    destructor Destroy; override;
    function CreateInstance: TDirectThread; virtual;
    property ThreadCount: Cardinal read GetThreadCount write SetThreadCount;
  end;

implementation

{ TThreadPool }

constructor TThreadPool.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AName);
  FQueueSplitter=TQueueSplitter.Create(AInputQueue, AName + '_Splitter_' + IntToStr(FID));
  if assigned(AInputQueue) then
    FInputPin.Add(AInputQueue);
  if assigned(AOutputQueue) then
    FOutputPin.Add(AOutputQueue);
  FAllThread:={$IFDEF FPC}TDirectThreadList{$ELSE}TObjectList<TDirectThread>{$ENDIF}.Create;
end;

function TThreadPool.CreateInstance: TDirectThread;
begin
  result:=nil;
end;

destructor TThreadPool.Destroy;
var
  dt: TDirectThread;
begin
  while (FAllThread.Count>0) do
  begin
    dt = FAllThread.Last;
    FAllThread.Remove(dt);
    FQueueSplitter.RemoveReceiver(dt.InputQueue);
    FreeAndNil(dt);
  end;
  FreeAndNil(FAllThread);
  FreeAndNil(FQueueSplitter);
  inherited;
end;

function TThreadPool.GetThreadCount: Cardinal;
begin
  result:=FAllThread.Count;
end;

procedure TThreadPool.SetThreadCount(const Value: Cardinal);
var
  cnt: Cardinal;
  dt: TDirectThread;
begin
  cnt:= FAllThread.Count;
  if Value<> cnt then
  begin
    if Value > cnt then
      while (Value > FAllThread.Count) do
      begin
        dt:= CreateInstance;
        if assigned(dt) then
        begin
          dt.SetOutputQueue(FOutputPin[0]);
          FQueueSplitter.AddReceiver(dt.InputQueue);
          FAllThread.Add(dt);
        end
        else
        begin
          SendErrorMsg('TThreadPool('+FName+').SetThreadCount 88: Error cast TDirectThread.');
          break;
        end;
      end
    else
      while FAllThread.Count>Value do
      begin
        dt = FAllThread.Last;
        FAllThread.Remove(dt);
        FQueueSplitter.RemoveReceiver(dt.InputQueue);
        FreeAndNil(dt);
      end;
  end;
end;

end.
