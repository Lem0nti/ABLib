unit ABL.VS.DecodedItem;

interface

uses
  ABL.Core.ThreadItem, ABL.VS.VSTypes, SyncObjs;

type
  TDecodedItem=class(TThreadItem)
  public
    procedure Push(AItem: Pointer); override;
  end;

implementation

{ TDecodedItem }

procedure TDecodedItem.Push(AItem: Pointer);
var
  DecodedFrame: PDecodedFrame;
begin
  FLock.Enter;
  try
    if assigned(PMain) then
    begin
      DecodedFrame:=PDecodedFrame(PMain);
      FreeMem(DecodedFrame^.Data);
      Dispose(DecodedFrame);
    end;
    PMain:=AItem;
    FWaitEmptyItems.ResetEvent;
    FWaitItemsEvent.SetEvent;
  finally
    FLock.Leave;
  end;
end;

end.
