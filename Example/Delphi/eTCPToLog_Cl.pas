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
  ReadedData: PTimedDataHeader;
  tmpString: PString;
  tmpAnsiString: AnsiString;
  tmpDataSize: integer;
begin
  ReadedData:=AInputData;
  tmpDataSize:=ReadedData.DataHeader.Size-SizeOf(TTimedDataHeader);
  SetLength(tmpAnsiString,tmpDataSize);
  Move(ReadedData.Data^,tmpAnsiString[1],tmpDataSize);
  new(tmpString);
  setstring(tmpString^, PChar(string(tmpAnsiString)),tmpDataSize);
  SendMessage(MSGReceiver,WM_ABL_THREAD_EXECUTED,NativeUint(tmpString),0);
end;

end.
