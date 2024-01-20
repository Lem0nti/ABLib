unit ABL.Core.DirectThread;

interface

uses
  ABL.Core.BaseThread, SysUtils, ABL.Core.Debug, SyncObjs;

type

  { TDirectThread }

  TDirectThread=class(TBaseThread)
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); virtual; abstract;
    procedure Execute; override;
  end;

implementation

{ TDirectThread }

procedure TDirectThread.Execute;
var
  Mess,Res: Pointer;
  ExitOnError: boolean;
begin
  FLastExec:=now;
  ExitOnError:=true;
  while not Terminated do
    try
      ExitOnError:=true;
      if assigned(FInputQueue) then
        FInputQueue.WaitForItems(INFINITE)
      else
      begin
        SendErrorMsg('TDirectThread('+ClassName+').Execute 36: no input queue');
        Stop;
      end;
      if (not Terminated)and assigned(FInputQueue) then
      begin
        while (FInputQueue.Count>0)and(not Terminated) do
        begin
          Mess:=FInputQueue.Pop;
          try
            Res:=nil;
            ExitOnError:=false;
            StartWatch;
            DoExecute(Mess,Res);
            IncreaseIteration(StopWatch);
            FLastExec:=now;
            if Terminated then
              exit;
            if assigned(Res) then
              if assigned(FOutputQueue) then
                FOutputQueue.Push(Res)
              else
                SendErrorMsg('TDirectThread.Execute '+ClassName+'('+FName+') 57: нет получателя для результата DoExecute');
          finally
            if assigned(Mess) then
              FreeMem(Mess);
          end;
        end;
      end;
    except on e: Exception do
      begin
        SendErrorMsg('TDirectThread.Execute '+ClassName+'('+FName+') 70: '+e.ClassName+' - '+e.Message);
        if ExitOnError then
          Stop;
      end;
    end;
end;

end.
