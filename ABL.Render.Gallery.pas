unit ABL.Render.Gallery;

interface

uses
  ABL.Render.TimerRender, ABL.VS.VSTypes, ABL.Core.BaseQueue, SysUtils;

type
  TGallery=class(TTimerRender)
  private
    FDropGlut: boolean;
    FrameList: array of Pointer;
  protected
    procedure DoExecute; override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
  end;

implementation

{ TGallery }

constructor TGallery.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  FDropGlut=true;
  FDrawer.ShowTime:=false;
  Run;
end;

procedure TGallery.DoExecute;
var
  ImageDataHeader,tmpImage: PImageDataHeader;
  rData,ToData: PByteArray;
  FromX,FromY,MaxHeight,OffsetFrom,OffsetTo,q,y,x: integer;
  PicturesDrawed: Cardinal;
  BytePerPixel: byte;
  tmpPointer: Pointer;
begin
  ImageDataHeader:=FPicture;
  FillChar(ImageDataHeader.Data^,ImageDataHeader.TimedDataHeader.DataHeader.Size-sizeof(TImageDataHeader),255);
  FromX=0;
  FromY=0;
  MaxHeight=0;
  FLock.Enter;
  try
    PicturesDrawed=0;
    for q:=0 to High(FrameList) do
    begin
      PicturesDrawed=q+1;
      tmpImage:=FrameList[q];
      if tmpImage.Width+FromX>=ImageDataHeader.Width then
      begin
        FromX=0;
        FromY=FromY+MaxHeight;
        MaxHeight=0;
      end;
      if tmpImage.Height+FromY>=ImageDataHeader.Height then
        break;
      if tmpImage.Height>MaxHeight then
        MaxHeight:=tmpImage.Height;
      rData=tmpImage.Data;
      if tmpImage.ImageType=itBGR then
        BytePerPixel=3
      else
        BytePerPixel=1;
      ToData:=ImageDataHeader.Data;
      for y:=0 to tmpImage.Height-1 do
      begin
        OffsetFrom:=y*tmpImage.Width*BytePerPixel;
        OffsetTo=((FromY+y)*ImageDataHeader.Width+FromX)*3;
        if BytePerPixel=3 then
          move(rData[OffsetFrom],ToData[OffsetTo],tmpImage.Width*3)
        else
          for x:=0 to tmpImage.Width-1 do
            FillChar(ToData[OffsetTo],3,rData[OffsetFrom+x]);
      end;
      FromX=FromX+tmpImage.Width;
    end;
    if (not Terminated) and (FDrawer.Draw(FPicture)<0) then
      FTerminated:=true;
    if FDropGlut then
      while (PicturesDrawed<length(FrameList)) do
      begin
        tmpPointer:=FrameList[High(FrameList)];
        FreeMem(rData);
        Delete(FrameList,High(FrameList),1);
      end;
  finally
    FLock.Leave;
  end;
end;

end.
