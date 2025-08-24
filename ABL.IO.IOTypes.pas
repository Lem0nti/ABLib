unit ABL.IO.IOTypes;     

{$IFDEF FPC}
{$mode objfpc}{$H+}{$modeswitch advancedrecords}
{$ENDIF}

interface

uses
  ABL.Core.CoreTypes, SysUtils;

type
  PTimedDataHeader=^TTimedDataHeader;
  TTimedDataHeader=record
    DataHeader: TDataHeader;
    Time: int64;
    Reserved: Int64;
    function Data: Pointer;
    procedure Init;
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

procedure TTimedDataHeader.Init;
var
  tmpLTimeStamp: TTimeStamp;
  Time: int64;
begin
  DataHeader.Init;
  DataHeader.DataType:=1;
  tmpLTimeStamp := DateTimeToTimeStamp(now);
  Time:=tmpLTimeStamp.Date*Int64(MSecsPerDay)+tmpLTimeStamp.Time-UnixTimeStart;
  Reserved:=0;
end;

end.
