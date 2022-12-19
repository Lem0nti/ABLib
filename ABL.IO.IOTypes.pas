unit ABL.IO.IOTypes;     

{$mode objfpc}{$H+}{$modeswitch advancedrecords}

interface

uses
  ABL.Core.CoreTypes;

type
  PTimedDataHeader=^TTimedDataHeader;
  TTimedDataHeader=record
    DataHeader: TDataHeader;
    Time: int64;
    Reserved: Int64;
    function Data: Pointer;
  end;

const
  UnixTimeStart   = 62135683200000;  //DateTimeToMilliseconds(UnixDateDelta);
  {$IFDEF UNIX}
  INVALID_SOCKET  =-1;
  SOCKET_ERROR    =-1;
  {$ENDIF}

implementation

{ TTimedDataHeader }

function TTimedDataHeader.Data: Pointer;
begin
  result:=Pointer(NativeUInt(@Self)+SizeOf(TTimedDataHeader));
end;

end.
