unit ABL.IO.IOTypes;

interface

type
  PDataFrame=^TDataFrame;
  TDataFrame=record
    Time: int64;
    Size: Cardinal;
    Reserved: Byte;
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
