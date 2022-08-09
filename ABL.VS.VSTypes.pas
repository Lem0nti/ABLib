unit ABL.VS.VSTypes;

interface

type
  TABLImageType = (itBGR, itGray, itBit);

  PDecodedFrame=^TDecodedFrame;
  TDecodedFrame=record
    Time: int64;
    Width,Height: Word;
    Left,Top: Word;
    ImageType: TABLImageType;
    Data: Pointer;
  end;

implementation

end.
