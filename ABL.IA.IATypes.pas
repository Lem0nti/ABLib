unit ABL.IA.IATypes;     

{$IFDEF FPC}
{$mode objfpc}{$H+}{$modeswitch advancedrecords}
{$ENDIF}

interface

uses
  Types;

type
  TArea = record
    Rect: TRect;
    Cnt: Cardinal;
  end;

  PRGBTriple=^TRGBTriple;
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
  result:=round(rgbtRed*0.2989+rgbtGreen*0.5870+rgbtBlue*0.1140);
end;

end.
