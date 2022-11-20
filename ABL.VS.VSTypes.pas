unit ABL.VS.VSTypes;

interface

uses
  ABL.IO.IOTypes;

type
  TABLImageType = (itBGR, itGray, itBit);

  PImageDataHeader=^TImageDataHeader;
  TImageDataHeader=record
    TimedDataHeader: TTimedDataHeader;
    Width,Height: Word;
    Left,Top: Word;
    ImageType: TABLImageType;
    FlipMarker: boolean;
    Reserved0: Word;
    Reserved1: integer;
  end;

  TImageData=record
    ImageDataHeader: TImageDataHeader;
    Data: Pointer;
  end;

implementation

end.
