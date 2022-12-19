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
    ReceiverList: array of TReceiverInfo;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue: TBaseQueue; AName: string = ''); reintroduce;
    procedure AddReceiver(AReceiver: TBaseQueue; ACutRect: TRect);
    procedure RemoveReceiver(AReceiver: TBaseQueue);
    procedure UpdateReceiver(AReceiver: TBaseQueue; ACutRect: TRect);
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
  DecodedFrame,OutputFrame: PImageDataHeader;
  AbsRect, ACutRect: TRect;
  y,q,hl,tmpDataSize: integer;
  tmpOutputQueue: TBaseQueue;
  BytesPerPixel: byte;
  tmpData: Pointer;
begin
  DecodedFrame:=AInputData;
  if DecodedFrame^.ImageType in [itBGR,itGray] then
  begin
    q:=0;
    FLock.Enter;
    try
      for q := 0 to high(ReceiverList) do
      begin
        ACutRect:=ReceiverList[q].CutRect;
        tmpOutputQueue:=ReceiverList[q].Receiver;
        if ACutRect.Left>ACutRect.Right then
        begin
          ACutRect.Left:=ACutRect.Right+ACutRect.Left;
          ACutRect.Right:=ACutRect.Left-ACutRect.Right;
          ACutRect.Left:=ACutRect.Left-ACutRect.Right;
        end;
        if ACutRect.Top>ACutRect.Bottom then
        begin
          ACutRect.Top:=ACutRect.Bottom+ACutRect.Top;
          ACutRect.Bottom:=ACutRect.Top-ACutRect.Bottom;
          ACutRect.Top:=ACutRect.Top-ACutRect.Bottom;
        end;
        //превращаем относительный прямоугольник в конкретный
        AbsRect:=Rect(Round(ACutRect.Left/10000*DecodedFrame^.Width),Round((ACutRect.Top)/10000*DecodedFrame^.Height),
            Round(ACutRect.Right/10000*DecodedFrame^.Width),Round((ACutRect.Bottom)/10000*DecodedFrame^.Height));
        while AbsRect.Width mod 4 > 0 do
          AbsRect.Width:=AbsRect.Width+1;
        if assigned(tmpOutputQueue) then
        begin
          if DecodedFrame^.ImageType=itBGR then
            BytesPerPixel:=3
          else
            BytesPerPixel:=1;
          tmpDataSize:=SizeOf(TImageDataHeader)+AbsRect.Width*AbsRect.Height*BytesPerPixel;
          GetMem(tmpData,tmpDataSize);
          Move(AInputData^,tmpData^,SizeOf(TImageDataHeader));
          OutputFrame:=tmpData;
          OutputFrame^.Width:=AbsRect.Width;
          OutputFrame^.Height:=AbsRect.Height;
          OutputFrame^.TimedDataHeader.DataHeader.Size:=tmpDataSize;
          for y := AbsRect.Top to AbsRect.Bottom-1 do
            Move(PByte(NativeUInt(DecodedFrame^.Data)+(y*DecodedFrame^.Width+AbsRect.Left)*BytesPerPixel)^,
                PByte(NativeUInt(OutputFrame^.Data)+((y-AbsRect.Top)*AbsRect.Width)*BytesPerPixel)^,AbsRect.Width*BytesPerPixel);
          tmpOutputQueue.Push(tmpData);
        end;
      end;
    finally
      FLock.Leave;
    end;
  end;
end;

procedure TImageCutter.RemoveReceiver(AReceiver: TBaseQueue);
var
  q: integer;
begin
  FLock.Enter;
  try
    for q := 0 to Length(ReceiverList)-1 do
      if ReceiverList[q].Receiver=AReceiver then
      begin
        Delete(ReceiverList,q,1);
        break;
      end;
  finally
    FLock.Leave;
  end;
end;

procedure TImageCutter.UpdateReceiver(AReceiver: TBaseQueue; ACutRect: TRect);
var
  q: integer;
begin
  FLock.Enter;
  try
    for q := 0 to Length(ReceiverList)-1 do
      if ReceiverList[q].Receiver=AReceiver then
      begin
        ReceiverList[q].CutRect:=ACutRect;
        break;
      end;
  finally
    FLock.Leave;
  end;
end;

end.
