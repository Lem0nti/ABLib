unit ABL.Core.QueueMultiplier;

interface

uses
  ABL.Core.DirectThread, ABL.Core.BaseQueue, {$IFDEF UNIX}fgl{$ELSE}Generics.Collections{$ENDIF},
  SyncObjs, ABL.Core.CoreUtils;

type
  TQueueMultiplier=class(TDirectThread)
  protected
    FReceiverList: {$IFDEF FPC}TBaseQueueList{$ELSE}TObjectList<TBaseQueue>{$ENDIF};
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue: TBaseQueue; AName: string = ''); reintroduce;
    destructor Destroy; override;
    procedure AddReceiver(AQueue: TBaseQueue);
    procedure RemoveReceiver(AQueue: TBaseQueue);
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
  sz: Cardinal;
begin
  if FReceiverList.Count>0 then
  begin
    sz:=DataSize(AInputData);
    if sz>0 then
    begin
      for i := 0 to FReceiverList.Count-2 do
      begin
        GetMem(q,sz);
        Move(AInputData^,q^,sz);
        FReceiverList[i].Push(q);
      end;
      FReceiverList[FReceiverList.Count-1].Push(AInputData);
      AInputData:=nil;
    end;
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
