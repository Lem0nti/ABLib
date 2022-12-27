unit ABL.Core.BaseQueue;

interface

uses
  Contnrs, SyncObjs, ABL.Core.BaseObject, {$IFDEF UNIX}fgl{$ELSE}Generics.Collections{$ENDIF};

type
  TABLQueue=class(Contnrs.TQueue)
  public
    property List;
  end;

  TBaseQueue=class(TBaseObject)
  private
    function GetLastInput: TDateTime;
  protected
    Queue: TABLQueue;
    FLastInput: TDateTime;
    FWaitEmptyItems,
    FWaitItemsEvent: TEvent;
  public
    constructor Create(AName: string=''); override;
    destructor Destroy; override;
    procedure Clear; virtual; abstract;
    function Count: Integer; virtual;
    function Pop: Pointer; virtual; abstract;
    procedure Push(AItem: Pointer); virtual; abstract;
    procedure SetEvent;
    /// <summary>
    /// Ожидание элементов.
    /// </summary>
    function WaitForItems(Timeout: Cardinal): TWaitResult;
    /// <summary>
    /// Ожидание опустошения.
    /// </summary>
    function WaitForEmpty(Timeout: Cardinal): TWaitResult;
    property LastInput: TDateTime read GetLastInput;
  end;

  {$IFDEF FPC}
  TBaseQueueList = specialize {$IFDEF UNIX}TFPGObjectList{$ELSE}TObjectList{$ENDIF}<TBaseQueue>;
  {$ENDIF}

var
  QueueList: {$IFDEF FPC}TBaseQueueList{$ELSE}TObjectList<TBaseQueue>{$ENDIF};

implementation

{ TRCLBaseQueue }

function TBaseQueue.Count: Integer;
begin
  FLock.Enter;
  try
    result:=Queue.Count;
  finally
    FLock.Leave;
  end;
end;

constructor TBaseQueue.Create(AName: string);
begin
  inherited Create(AName);
  Queue:=TABLQueue.Create;
  FWaitItemsEvent:=TEvent.Create(nil,true,false,'');
  FWaitEmptyItems:=TEvent.Create(nil,true,false,'');
  FWaitEmptyItems.SetEvent;
  QueueList.Add(Self);
end;

destructor TBaseQueue.Destroy;
begin
  FLock.Enter;
  try
    QueueList.Remove(Self);
    FWaitItemsEvent.SetEvent;
    FWaitEmptyItems.SetEvent;
    FWaitEmptyItems.Free;
    FWaitItemsEvent.Free;
    Queue.Free;
  finally
    FLock.Leave;
  end;
  inherited;
end;

function TBaseQueue.GetLastInput: TDateTime;
begin
  FLock.Enter;
  try
    result:=FLastInput;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseQueue.SetEvent;
begin
  FWaitItemsEvent.SetEvent;
end;

function TBaseQueue.WaitForEmpty(Timeout: Cardinal): TWaitResult;
begin
  Result:=FWaitEmptyItems.WaitFor(Timeout);
end;

function TBaseQueue.WaitForItems(Timeout: Cardinal): TWaitResult;
begin
  Result:=FWaitItemsEvent.WaitFor(Timeout);
end;

initialization
  QueueList:={$IFDEF FPC}TBaseQueueList{$ELSE}TObjectList<TBaseQueue>{$ENDIF}.Create;
  QueueList.{$IFDEF UNIX}FreeObjects{$ELSE}OwnsObjects{$ENDIF}:=false;

finalization
  QueueList.Free;

end.
