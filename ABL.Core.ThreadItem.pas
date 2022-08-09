unit ABL.Core.ThreadItem;

interface

uses
  ABL.Core.BaseQueue;

type
  TDataNotify=procedure(var AData: Pointer) of object;

  TThreadItem=class(TBaseQueue)
  private
    FClearPrior: TDataNotify;
  protected
    PMain: Pointer;
  public
    constructor Create(AName: string = ''); override;
    function Count: Integer; override;
    function Pop: Pointer; override;
    procedure Push(AItem: Pointer); override;
    property OnClearPrior: TDataNotify read FClearPrior write FClearPrior;
  end;

implementation

{ TThreadItem }

function TThreadItem.Count: Integer;
begin
  Lock;
  try
    if assigned(PMain) then
      result:=1
    else
      result:=0;
  finally
    Unlock;
  end;
end;

constructor TThreadItem.Create(AName: string);
begin
  inherited Create(AName);
  PMain:=nil;
  FClearPrior:=nil;
end;

function TThreadItem.Pop: Pointer;
begin
  Lock;
  try
    result:=PMain;
    PMain:=nil;
    FWaitEmptyItems.SetEvent;
    FWaitItemsEvent.ResetEvent;
  finally
    Unlock;
  end;
end;

procedure TThreadItem.Push(AItem: Pointer);
begin
  Lock;
  try
    if assigned(PMain) then
    begin
      if assigned(FClearPrior) then
        FClearPrior(PMain)
      else
        {$IFDEF FPC}
        Freemem(PMain);
        {$ELSE}
        Dispose(PMain);
        {$ENDIF}
    end;
    PMain:=AItem;
    FWaitEmptyItems.ResetEvent;
    FWaitItemsEvent.SetEvent;
  finally
    Unlock;
  end;
end;

end.
