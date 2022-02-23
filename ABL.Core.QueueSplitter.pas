unit ABL.Core.QueueSplitter;

interface

uses
  ABL.Core.DirectThread, ABL.Core.BaseQueue, {$IFDEF UNIX}fgl{$ELSE}Generics.Collections{$ENDIF};

type
  TQueueSplitter=class(TDirectThread)
  private
    FReceiverList: {$IFDEF FPC}TBaseQueueList{$ELSE}TObjectList<TBaseQueue>{$ENDIF};
    CurIndex: integer;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue: TBaseQueue; AName: string = ''); reintroduce;
    destructor Destroy; override;
    procedure AddReceiver(AQueue: TBaseQueue);
  end;

implementation

{ TQueueSplitter }

procedure TQueueSplitter.AddReceiver(AQueue: TBaseQueue);
begin
  FReceiverList.Add(AQueue);
end;

constructor TQueueSplitter.Create(AInputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,nil,AName);
  FReceiverList:={$IFDEF FPC}TBaseQueueList{$ELSE}TObjectList<TBaseQueue>{$ENDIF}.Create;
  FReceiverList.{$IFDEF UNIX}FreeObjects{$ELSE}OwnsObjects{$ENDIF}:=False;
end;

destructor TQueueSplitter.Destroy;
begin
  if assigned(FReceiverList) then
    FReceiverList.Free;
  inherited;
end;

procedure TQueueSplitter.DoExecute(var AInputData, AResultData: Pointer);
begin
  if FReceiverList.Count>0 then
  begin
    FReceiverList[CurIndex].Push(AInputData);
    AInputData:=nil;
    inc(CurIndex);
    if CurIndex>=FReceiverList.Count then
      CurIndex:=0;
  end;
end;

end.
