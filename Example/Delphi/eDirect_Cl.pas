unit eDirect_Cl;

interface

uses
  ABL.Core.DirectThread, eMessage, Windows;

type
  TDirect=class(TDirectThread)
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  end;

implementation

{ TDirect }

procedure TDirect.DoExecute(var AInputData, AResultData: Pointer);
var
  tmpString: PString;
begin
  new(tmpString);
  setstring(tmpString^, PChar(FName+'.DoExecute'), length(FName+'.DoExecute'));
  SendMessage(MSGReceiver,WM_ABL_THREAD_EXECUTED,NativeUint(tmpString),0);
  if assigned(FOutputQueue) then
  begin
    AResultData:=AInputData;
    AInputData:=nil;
  end;
end;

end.
