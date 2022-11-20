unit ABL.IO.IOTypes;

interface

uses
  ABL.Core.CoreTypes;

type
  PTimedDataHeader=^TTimedDataHeader;
  TTimedDataHeader=record
    DataHeader: TDataHeader;
    Time: int64;
    Reserved: Int64;
  end;

  TTimedData=record
    TimedDataHeader: TTimedDataHeader;
    Data: Pointer;
  end;

const
  UnixTimeStart   = 62135683200000;  //DateTimeToMilliseconds(UnixDateDelta);
  {$IFDEF UNIX}
  INVALID_SOCKET  =-1;
  SOCKET_ERROR    =-1;
  {$ENDIF}

implementation

end.
