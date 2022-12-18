unit eTimer_Cl;

interface

uses
  ABL.Core.TimerThread, Windows, eMessage;

type
  TABLTimer=class(TTimerThread)
  protected
    procedure DoExecute; override;
    procedure DoReceive(var AInputData: Pointer); override;
  end;

implementation

{ TABLTimer }

procedure TABLTimer.DoExecute;
var
  tmpString: PString;
begin
  new(tmpString);
  setstring(tmpString^, PChar(FName+'.DoExecute'), length(FName+'.DoExecute'));
  SendMessage(MSGReceiver,WM_ABL_THREAD_EXECUTED,NativeUint(tmpString),0);
  if assigned(FOutputQueue) then
  begin
    new(tmpString);
    OutputQueue.Push(tmpString);
  end;
end;

procedure TABLTimer.DoReceive(var AInputData: Pointer);
var
  tmpString: PString;
begin
  new(tmpString);
  setstring(tmpString^, PChar(FName+'.DoReceive'), length(FName+'.DoReceive'));
  SendMessage(MSGReceiver,WM_ABL_THREAD_EXECUTED,NativeUint(tmpString),0);
end;

end.
