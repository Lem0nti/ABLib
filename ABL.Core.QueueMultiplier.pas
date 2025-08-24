unit ABL.Core.QueueMultiplier;

interface

uses
  ABL.Core.DirectThread, ABL.Core.BaseQueue,
  ABL.Core.CoreUtils;

type
  TQueueMultiplier=class(TDirectThread)
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue: TBaseQueue; AName: string = ''); reintroduce;
  end;

implementation

{ TQueueMultiplier }

constructor TQueueMultiplier.Create(AInputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,nil,AName);
  Start;
end;

procedure TQueueMultiplier.DoExecute(var AInputData, AResultData: Pointer);
var
  i: integer;
  q: Pointer;
  sz: Cardinal;
begin
  if FOutputPin.Count>0 then
  begin
    sz:=DataSize(AInputData);
    if sz>0 then
    begin
      for i := 0 to FOutputPin.Count-2 do
      begin
        GetMem(q,sz);
        Move(AInputData^,q^,sz);
        FOutputPin[i].Push(q);
      end;
      FOutputPin[FOutputPin.Count-1].Push(AInputData);
      AInputData:=nil;
    end;
  end;
end;

end.
