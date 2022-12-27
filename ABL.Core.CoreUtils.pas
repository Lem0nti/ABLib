unit ABL.Core.CoreUtils;

interface

function DataSize(const P: Pointer): Cardinal; inline;

implementation

function DataSize(const P: Pointer): Cardinal;
begin
  result:=0;
  if (PWord(P)^=16961) then
    result:=PCardinal(Pointer(NativeUInt(P)+4))^;
end;

end.
