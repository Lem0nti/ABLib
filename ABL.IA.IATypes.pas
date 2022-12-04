unit ABL.IA.IATypes;

interface

//uses
//  Windows;

type
  TRGBTriple = record
    rgbtBlue: Byte;
    rgbtGreen: Byte;
    rgbtRed: Byte;
    function Brightness: Byte;
  end;

  PRGBArray = ^TRGBArray;
  TRGBArray = array [0..0] of TRGBTriple;

implementation

{ TRGBTriple }

function TRGBTriple.Brightness: Byte;
begin
  result:=round(rgbtRed*0.2989+rgbtGreen*0.5870+rgbtRed*0.1140);
end;

end.
