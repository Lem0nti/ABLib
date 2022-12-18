unit eTCPToLog_Cl;

interface

uses
  ABL.Core.DirectThread, StdCtrls, ABL.IO.IOTypes, SysUtils, eMessage, Windows;

type
  TTCPToLog=class(TDirectThread)
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  end;

implementation

{ TTCPToLog }

procedure TTCPToLog.DoExecute(var AInputData, AResultData: Pointer);
var
  ReadedData: PDataFrame;
  tmpString: PString;
  tmpAnsiString: AnsiString;
begin
  ReadedData:=PDataFrame(AInputData);
  SetLength(tmpAnsiString,ReadedData.Size);
  Move(ReadedData.Data^,tmpAnsiString[1],ReadedData.Size);
  new(tmpString);
  setstring(tmpString^, PChar(string(tmpAnsiString)), ReadedData.Size);
  Dispose(ReadedData.Data);
  SendMessage(MSGReceiver,WM_ABL_THREAD_EXECUTED,NativeUint(tmpString),0);
end;

end.
