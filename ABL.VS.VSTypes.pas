unit ABL.VS.VSTypes;  

{$mode objfpc}{$H+}{$modeswitch advancedrecords}

interface

uses
  ABL.IO.IOTypes;

type
  TABLImageType = (itBGR, itGray, itBit, itGrayIntegral, itBitIntegral);

  PImageDataHeader=^TImageDataHeader;
  TImageDataHeader=record
    TimedDataHeader: TTimedDataHeader;
    Width,Height: Word;
    Left,Top: Word;
    ImageType: TABLImageType;
    FlipMarker: boolean;
    Reserved0: Word;
    Reserved1: integer;
    function Data: Pointer;
  end;

implementation

{ TImageDataHeader }

function TImageDataHeader.Data: Pointer;
begin
  result:=Pointer(NativeUInt(@Self)+SizeOf(TImageDataHeader));
end;

end.
