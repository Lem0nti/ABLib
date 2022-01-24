unit ABL.VS.DecodedMultiplier;

interface

uses
  ABL.Core.QueueMultiplier, ABL.VS.VSTypes;

type
  TDecodedMultiplier=class(TQueueMultiplier)
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  end;

implementation

{ TDecodedMultiplier }

procedure TDecodedMultiplier.DoExecute(var AInputData, AResultData: Pointer);
var
  i: integer;
  DecodedFrame: PDecodedFrame;
begin
  if FReceiverList.Count>0 then
  begin
    for i := 0 to FReceiverList.Count-2 do
    begin
      new(DecodedFrame);
      DecodedFrame.Time:=PDecodedFrame(AInputData).Time;
      DecodedFrame.Width:=PDecodedFrame(AInputData).Width;
      DecodedFrame.Height:=PDecodedFrame(AInputData).Height;
      GetMem(DecodedFrame.Data,DecodedFrame.Width*DecodedFrame.Height*3);
      Move(PDecodedFrame(AInputData).Data^,DecodedFrame.Data^,DecodedFrame.Width*DecodedFrame.Height*3);
      FReceiverList[i].Push(DecodedFrame);
    end;
    FReceiverList[FReceiverList.Count-1].Push(AInputData);
    AInputData:=nil;
  end;
end;

end.
