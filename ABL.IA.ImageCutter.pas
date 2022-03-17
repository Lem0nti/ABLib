unit ABL.IA.ImageCutter;

interface

uses
  ABL.Core.DirectThread, ABL.VS.VSTypes, Types, SyncObjs, ABL.Core.BaseQueue;

type
  TReceiverInfo=record
    Receiver: TBaseQueue;
    CutRect: TRect;
  end;

  TImageCutter=class(TDirectThread)
  private
    ReceiverList: TArray<TReceiverInfo>;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue: TBaseQueue; AName: string = ''); reintroduce;
    procedure AddReceiver(AReceiver: TBaseQueue; ACutRect: TRect);
  end;

implementation

{ TImageCutter }

procedure TImageCutter.AddReceiver(AReceiver: TBaseQueue; ACutRect: TRect);
begin
  FLock.Enter;
  try
    SetLength(ReceiverList,Length(ReceiverList)+1);
    ReceiverList[high(ReceiverList)].Receiver:=AReceiver;
    ReceiverList[high(ReceiverList)].CutRect:=ACutRect;
  finally
    FLock.Leave;
  end;
end;

constructor TImageCutter.Create(AInputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,nil,AName);
  Active:=true;
end;

procedure TImageCutter.DoExecute(var AInputData, AResultData: Pointer);
var
  DecodedFrame,OutputFrame: PDecodedFrame;
  AbsRect, ACutRect: TRect;
  y,q,hl: integer;
  tmpOutputQueue: TBaseQueue;
begin
  DecodedFrame:=PDecodedFrame(AInputData);
  try
    q:=0;
    while true do
    begin
      FLock.Enter;
      hl:=high(ReceiverList);
      if q<=hl then
      begin
        ACutRect:=ReceiverList[q].CutRect;
        tmpOutputQueue:=ReceiverList[q].Receiver;
      end;
      FLock.Leave;
      if q>hl then
        break
      else
      begin
        //превращаем относительный прямоугольник в конкретный
        AbsRect:=Rect(Round(ACutRect.Left/10000*DecodedFrame.Width),Round((ACutRect.Top)/10000*DecodedFrame.Height),
            Round(ACutRect.Right/10000*DecodedFrame.Width),Round((ACutRect.Bottom)/10000*DecodedFrame.Height));
        while AbsRect.Width mod 4 > 0 do
          AbsRect.Width:=AbsRect.Width+1;
        new(OutputFrame);
        OutputFrame.Width:=AbsRect.Width;
        OutputFrame.Height:=AbsRect.Height;
        OutputFrame.Time:=DecodedFrame.Time;
        GetMem(OutputFrame^.Data,OutputFrame.Width*OutputFrame.Height*3);
        for y := AbsRect.Top to AbsRect.Bottom do
          Move(PByte(NativeUInt(DecodedFrame.Data)+(y*DecodedFrame.Width+AbsRect.Left)*3)^,
              PByte(NativeUInt(OutputFrame.Data)+((y-AbsRect.Top)*AbsRect.Width)*3)^,AbsRect.Width*3);
        inc(q);
        tmpOutputQueue.Push(OutputFrame);
      end;
    end;
  finally
    FreeMem(DecodedFrame.Data);
  end;
end;

end.
