unit ABL.IA.LinkComponent;

interface

uses
  ABL.Core.DirectThread, ABL.Core.BaseQueue, ABL.VS.VSTypes, Types, ABL.IA.IATypes, SysUtils,
  Generics.Collections, ABL.IO.IOTypes, SyncObjs;

type
  TLinkComponent=class(TDirectThread)
  private
    FMinSize: integer;
    function GetMinSize: integer;
    procedure SetMinSize(const Value: integer);
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); reintroduce;
    property MinSize: integer read GetMinSize write SetMinSize;
  end;

implementation

{ TLinkComponent }

constructor TLinkComponent.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  FMinSize:=16;
  Start;
end;

procedure TLinkComponent.DoExecute(var AInputData, AResultData: Pointer);
const
  MaxRDepth = 50000;
var
  FCurImage: PImageDataHeader;
  PictureData,ResultArray: PByteArray;
  tmpMinSize,tmpDataSize,x,y: integer;
  tmpCluster: TArea;
  tmpClusterPoint: array of TPoint;
  ClusterTips: TQueue<TPoint>;
  RDepth,k: integer;
  Offset,CurByte,CurBit: integer;
  p: TPoint;
  TimedDataHeader: PTimedDataHeader;
  ResultData: Pointer;

  procedure Check(AX,AY: Word);
  begin
    Inc(RDepth);
    Offset:=AY*FCurImage.Width+AX;
    CurByte:=Offset div 8;
    CurBit:=Offset mod 8;
    if RDepth>=MaxRDepth then
    begin
      if RDepth=MaxRDepth then
        ClusterTips.Enqueue(Point(AX,AY));
    end
    //текущий пиксель чёрный?
    else if (PictureData[CurByte] shr CurBit) and 1 = 0 then
    begin
      PictureData[CurByte]:=PictureData[CurByte] or (1 shl CurBit);
      tmpClusterPoint:=tmpClusterPoint+[Point(AX,AY)];
      if tmpCluster.Rect.Left>AX then
        tmpCluster.Rect.Left:=AX
      else if tmpCluster.Rect.Right<AX then
        tmpCluster.Rect.Right:=AX;
      if tmpCluster.Rect.Top>AY then
        tmpCluster.Rect.Top:=AY
      else if tmpCluster.Rect.Bottom<AY then
        tmpCluster.Rect.Bottom:=AY;
      if AX>0 then
      begin
        Check(AX-1,AY);
        if AY<FCurImage.Height-1 then
          Check(AX-1,AY+1);
      end;
      if AY>0 then
      begin
        Check(AX,AY-1);
        if AX>0 then
          Check(AX-1,AY-1);
      end;
      if AX<FCurImage.Width-1 then
      begin
        Check(AX+1,AY);
        if AY>0 then
          Check(AX+1,AY-1);
      end;
      if AY<FCurImage.Height-1 then
      begin
        Check(AX,AY+1);
        if AX<FCurImage.Width-1 then
          Check(AX+1,AY+1);
      end;
    end;
    Dec(RDepth);
  end;

begin
  FCurImage:=AInputData;
  if FCurImage.ImageType=itBit then
  begin
    PictureData:=FCurImage.Data;
    FLock.Enter;
    tmpMinSize:=FMinSize;
    FLock.Leave;
    ClusterTips:=TQueue<TPoint>.Create;
    try
      for y:=0 to FCurImage.Height-1 do
        for x:=0 to FCurImage.Width-1 do
        begin
          if FTerminated then
            exit;
          Offset:=y*FCurImage.Width+x;
          CurByte:=Offset div 8;
          CurBit:=Offset mod 8;
          //текущий пиксель чёрный?
          if (PictureData[CurByte] shr CurBit) and 1 = 0 then
          begin
//            tmpClusterPoint:=tmpClusterPoint+[Point(x,y)];
            tmpCluster.Rect:=Rect(10000,10000,0,0);
            ClusterTips.Clear;
            ClusterTips.Enqueue(Point(x,y)); // добавить в массив текущие ху
            while ClusterTips.Count>0 do
            begin
              RDepth:=0;
              p:=ClusterTips.Dequeue;
              Check(p.x, p.y);
            end;
            k:=length(tmpClusterPoint);
            if (tmpCluster.Rect.Width>=tmpMinSize)and(tmpCluster.Rect.Height>=tmpMinSize)and(k>tmpMinSize*3) then
            begin
              tmpDataSize:=SizeOf(TTimedDataHeader)+SizeOf(TArea)+k*sizeof(TPoint)+16;  //почему?
              GetMem(ResultData,tmpDataSize);
              TimedDataHeader:=ResultData;
              TimedDataHeader.DataHeader.Magic:=16961;
              TimedDataHeader.DataHeader.Version:=0;
              TimedDataHeader.DataHeader.DataType:=1;
              TimedDataHeader.DataHeader.Size:=tmpDataSize;
              TimedDataHeader.Time:=FCurImage.TimedDataHeader.Time;
              tmpCluster.Cnt:=k;
              ResultArray:=TimedDataHeader.Data;
              Move(tmpCluster,ResultArray[0],SizeOf(TArea));
              Move(tmpClusterPoint[0],ResultArray[SizeOf(TArea)],k*SizeOf(TPoint));
              if assigned(FOutputQueue) then
                FOutputQueue.Push(ResultData);
            end;
            tmpClusterPoint:=[];
          end;
        end;
    finally
      ClusterTips.Free;
    end;
  end;
end;

function TLinkComponent.GetMinSize: integer;
begin
  FLock.Enter;
  result:=FMinSize;
  FLock.Leave;
end;

procedure TLinkComponent.SetMinSize(const Value: integer);
begin
  FLock.Enter;
  FMinSize:=Value;
  FLock.Leave;
end;

end.
