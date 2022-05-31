unit ABL.Core.QueueMultiplier;

interface

uses
  ABL.Core.DirectThread, ABL.Core.BaseQueue, {$IFDEF UNIX}fgl{$ELSE}Generics.Collections{$ENDIF}, SyncObjs;

type
  TDataMultiply=procedure(AInputData: Pointer; var AResultData: Pointer) of object;

  TQueueMultiplier=class(TDirectThread)
  private
    FOnMultiply: TDataMultiply;
  protected
    FReceiverList: {$IFDEF FPC}TBaseQueueList{$ELSE}TObjectList<TBaseQueue>{$ENDIF};
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue: TBaseQueue; AName: string = ''); reintroduce;
    destructor Destroy; override;
    procedure AddReceiver(AQueue: TBaseQueue);
    procedure RemoveReceiver(AQueue: TBaseQueue);
    property OnMultiply: TDataMultiply read FOnMultiply write FOnMultiply;
  end;

implementation

{ TQueueMultiplier }

procedure TQueueMultiplier.AddReceiver(AQueue: TBaseQueue);
begin
  FLock.Enter;
  try
    FReceiverList.Add(AQueue);
  finally
    FLock.Leave;
  end;
end;

constructor TQueueMultiplier.Create(AInputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,nil,AName);
  FReceiverList:={$IFDEF FPC}TBaseQueueList{$ELSE}TObjectList<TBaseQueue>{$ENDIF}.Create;
  FReceiverList.{$IFDEF UNIX}FreeObjects{$ELSE}OwnsObjects{$ENDIF}:=false;
  FOnMultiply:=nil;
  Active:=true;
end;

destructor TQueueMultiplier.Destroy;
begin
  if assigned(FReceiverList) then
    FReceiverList.Free;
  inherited;
end;

procedure TQueueMultiplier.DoExecute(var AInputData, AResultData: Pointer);
var
  i: integer;
  q: Pointer;
begin
  if (FReceiverList.Count>0) and assigned(FOnMultiply) then
  begin
    for i := 0 to FReceiverList.Count-2 do
    begin
      FOnMultiply(AInputData,q);
      FReceiverList[i].Push(q);
    end;
    FReceiverList[FReceiverList.Count-1].Push(AInputData);
    AInputData:=nil;
  end;
end;

procedure TQueueMultiplier.RemoveReceiver(AQueue: TBaseQueue);
begin
  FLock.Enter;
  try
    FReceiverList.Remove(AQueue);
  finally
    FLock.Leave;
  end;
end;

end.
