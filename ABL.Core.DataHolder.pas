unit ABL.Core.DataHolder;

interface

uses
  ABL.Core.ThreadItem, SysUtils, ABL.Core.CoreUtils;

type
  TDataHolder=class(TThreadItem)
  public
    constructor Create(AName: string = ''); override;
    function Pop: Pointer; override;
  end;

implementation

{ TDataHolder }

constructor TDataHolder.Create(AName: string);
begin
  inherited Create(AName);
  if AName='' then
    FName='TDataHolder_'+IntToStr(FID);
end;

function TDataHolder.Pop: Pointer;
var
  sz: Cardinal;
begin
  FLock.Enter;
  if assigned(PMain) then
  begin
    sz:=DataSize(PMain);
    GetMem(result,sz);
    Move(PMain^,result^,sz);
  end;
  FLock.Leave;
end;

end.
