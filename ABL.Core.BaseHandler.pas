unit ABL.Core.BaseHandler;

interface

uses
  ABL.Core.BaseObject, ABL.Core.BaseQueue,
  {$IFDEF UNIX}fgl, linux, unixtype{$ELSE}Generics.Collections, Windows{$ENDIF};

type
  TMessageNotify = procedure(AMessage: string) of object;

  {$IFDEF FPC}
  TBaseQueueList = specialize {$IFDEF UNIX}TFPGObjectList{$ELSE}TObjectList{$ENDIF}<TBaseQueue>;
  {$ENDIF}

  TBaseHandler=class(TBaseObject)
  private
    FOnMessage: TMessageNotify;
    function GetOnMessage: TMessageNotify;
    procedure SetOnMessage(const Value: TMessageNotify);
  protected
    FInputPin, FOutputPin: {$IFDEF FPC}TBaseQueueList{$ELSE}TObjectList<TBaseQueue>{$ENDIF};
    procedure AddSender(Queue: TBaseQueue);
    procedure DoMessage(AMessage: string); virtual;
    procedure RemoveSender(Index: Cardinal); overload;
    procedure RemoveSender(Queue: TBaseQueue); overload;
  public
    constructor Create(AName: string = ''); override;
    destructor Destroy; override;
    function AddReceiver(Queue: TBaseQueue): integer; virtual;
    function InputQueue(Index: Cardinal=0): TBaseQueue; virtual;
    function OutputCount: integer;
    function OutputQueue(Index: Cardinal=0): TBaseQueue; virtual;
    procedure RemoveReceiver(Index: Cardinal); overload;
    function RemoveReceiver(Queue: TBaseQueue): boolean; overload;
    property OnMessage: TMessageNotify read GetOnMessage write SetOnMessage;
  end;

  {$IFDEF FPC}
  TBaseHandlerList = specialize {$IFDEF UNIX}TFPGObjectList{$ELSE}TObjectList{$ENDIF}<TBaseHandler>;
  {$ENDIF}

var
  HandlerList: {$IFDEF FPC}TBaseHandlerList{$ELSE}TObjectList<TBaseHandler>{$ENDIF};

implementation

{ TBaseHandler }

function TBaseHandler.AddReceiver(Queue: TBaseQueue): integer;
begin
  FLock.Enter;
  result:=FOutputPin.Add(Queue);
  FLock.Leave;
end;

procedure TBaseHandler.AddSender(Queue: TBaseQueue);
begin
  FLock.Enter;
  FInputPin.Add(Queue);
  FLock.Leave;
end;

constructor TBaseHandler.Create(AName: string);
begin
  inherited;
  FInputPin:={$IFDEF FPC}TBaseQueueList{$ELSE}TObjectList<TBaseQueue>{$ENDIF}.Create;
  FInputPin.{$IFDEF UNIX}FreeObjects{$ELSE}OwnsObjects{$ENDIF}:=false;
  FOutputPin:={$IFDEF FPC}TBaseQueueList{$ELSE}TObjectList<TBaseQueue>{$ENDIF}.Create;
  FOutputPin.{$IFDEF UNIX}FreeObjects{$ELSE}OwnsObjects{$ENDIF}:=false;
  HandlerList.Add(Self);
end;

destructor TBaseHandler.Destroy;
begin
  HandlerList.Remove(Self);
  FInputPin.Free;
  FOutputPin.Free;
  inherited;
end;

procedure TBaseHandler.DoMessage(AMessage: string);
begin
  if assigned(FOnMessage) then
    FOnMessage(AMessage);
end;

function TBaseHandler.GetOnMessage: TMessageNotify;
begin
  FLock.Enter;
  result:=FOnMessage;
  FLock.Leave;
end;

function TBaseHandler.InputQueue(Index: Cardinal): TBaseQueue;
begin
  if Index<FInputPin.Count then
    result:=FInputPin[Index]
  else
    result:=nil;
end;

function TBaseHandler.OutputCount: integer;
begin
  result:=FOutputPin.Count;
end;

function TBaseHandler.OutputQueue(Index: Cardinal): TBaseQueue;
begin
  if Index<FOutputPin.Count then
    result:=FOutputPin[Index]
  else
    result:=nil;
end;

procedure TBaseHandler.RemoveReceiver(Index: Cardinal);
begin
  FLock.Enter;
  if Index<FOutputPin.Count then
    FOutputPin.Delete(Index);
  FLock.Leave;
end;

function TBaseHandler.RemoveReceiver(Queue: TBaseQueue): boolean;
begin
  FLock.Enter;
  result:=FOutputPin.Remove(Queue)>=0;
  FLock.Leave;
end;

procedure TBaseHandler.RemoveSender(Index: Cardinal);
begin
  FLock.Enter;
  if Index<FInputPin.Count then
    FInputPin.Delete(Index);
  FLock.Leave;
end;

procedure TBaseHandler.RemoveSender(Queue: TBaseQueue);
begin
  FLock.Enter;
  FInputPin.Remove(Queue);
  FLock.Leave;
end;

procedure TBaseHandler.SetOnMessage(const Value: TMessageNotify);
begin
  FLock.Enter;
  FOnMessage:=Value;
  FLock.Leave;
end;

initialization
  HandlerList:={$IFDEF FPC}TBaseThreadList{$ELSE}TObjectList<TBaseHandler>{$ENDIF}.Create;
  HandlerList.{$IFDEF UNIX}FreeObjects{$ELSE}OwnsObjects{$ENDIF}:=false;

finalization
  HandlerList.Free;

end.
