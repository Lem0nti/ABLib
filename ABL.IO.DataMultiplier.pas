unit ABL.IO.DataMultiplier;

interface

uses
  ABL.Core.QueueMultiplier, ABL.IO.IOTypes;

type
  TDataMultiplier=class(TQueueMultiplier)
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  end;

implementation

{ TDataMultiplier }

procedure TDataMultiplier.DoExecute(var AInputData, AResultData: Pointer);
var
  i: integer;
  DataFrame: PDataFrame;
begin
  if FReceiverList.Count>0 then
  begin
    for i := 0 to FReceiverList.Count-2 do
    begin
      new(DataFrame);
      DataFrame.Time:=PDataFrame(AInputData).Time;
      DataFrame.Reserved:=PDataFrame(AInputData).Reserved;
      DataFrame.Size:=PDataFrame(AInputData).Size;
      GetMem(DataFrame.Data,DataFrame.Size);
      Move(PDataFrame(AInputData).Data^,DataFrame.Data^,DataFrame.Size);
      FReceiverList[i].Push(DataFrame);
    end;
    FReceiverList[FReceiverList.Count-1].Push(AInputData);
    AInputData:=nil;
  end;
end;

end.
