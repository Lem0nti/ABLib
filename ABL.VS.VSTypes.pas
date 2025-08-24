unit ABL.VS.VSTypes;

{$IFDEF FPC}
{$mode objfpc}{$H+}{$modeswitch advancedrecords}
{$ENDIF}

interface

uses
  ABL.IO.IOTypes;

type
  TABLImageType = (itBGR, itGray, itBit, itGrayIntegral, itBitIntegral, itWordIntegral, itWord);

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
    procedure Init;
  end;

implementation

{ TImageDataHeader }

function TImageDataHeader.Data: Pointer;
begin
  result:=Pointer(NativeUInt(@Self)+SizeOf(TImageDataHeader));
end;

procedure TImageDataHeader.Init;
begin
  TimedDataHeader.Init;
  TimedDataHeader.DataHeader.DataType:=2;
  Left:=0;
  Top:=0;
end;

end.
