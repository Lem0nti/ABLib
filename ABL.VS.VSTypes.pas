unit ABL.VS.VSTypes;

interface

type
  PDecodedFrame=^TDecodedFrame;
  TDecodedFrame=record
    Time: int64;
    Width,Height: Word;
    Data: Pointer;
  end;

implementation

end.
