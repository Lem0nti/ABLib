unit ABL.Core.CoreTypes;

interface

type
  PDataHeader=^TDataHeader;
  TDataHeader=record
    Magic: Word;     //всегда должен быть равен 16961
    Version: byte;   //0
    DataType: byte;  //0 для TDataHeader
    Size: Cardinal;  //размер данных вместе с заголовком
    Reserved: int64; //выравнивание до 16
    function Data: Pointer;
    procedure Init;
  end;

  TPointerMethod = procedure(var AInputData: Pointer) of object;
  TPointerFunction = function: Pointer;
  TWideStringFunction = function: WideString;
  TSetParamProc= procedure(Name: WideString; Value: WideString; AInstance: Pointer);

implementation

{ TDataHeader }

function TDataHeader.Data: Pointer;
begin
  result:=Pointer(NativeUInt(@Self)+SizeOf(TDataHeader));
end;

procedure TDataHeader.Init;
begin
  Magic:=16961;
  Version:=0;
  DataType:=0;
end;

end.
