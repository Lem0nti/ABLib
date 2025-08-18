unit ABL.Core.CoreTypes;

interface

type
  PDataHeader=^TDataHeader;
  TDataHeader=record
    Magic: Word;     //всегда должен быть равен 16961
    Version: byte;   //0
    DataType: byte;  //0 для TDataHeader
    Size: Cardinal;  //размер данных вместе с заголовком
  end;

  TData=record
    DataHeader: TDataHeader;
    Data: Pointer;
  end;

  TPointerMethod = procedure(var AInputData: Pointer) of object;
  TPointerFunction = function: Pointer;
  TWideStringFunction = function: WideString;
  TSetParamProc= procedure(Name: WideString; Value: WideString; AInstance: Pointer);

implementation

end.
