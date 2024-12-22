unit ABL.Render.ImageRender;

interface

uses
  ABL.Render.TimerRender, ABL.VS.VSTypes, ABL.Core.BaseQueue, SysUtils, ABL.Core.Debug, SyncObjs;

type
  TImageRender=class(TTimerRender)
  public
    procedure DoReceive(var AInputData: Pointer); override;
  end;

implementation

{ TImageRender }

procedure TImageRender.DoReceive(var AInputData: Pointer);
var
  ImageDataHeader: PImageDataHeader;
  y,dstY,OffsetFrom,OffsetTo,CopyCount: integer;
  tmpInput,tmpPicture: PByteArray;
begin
  if assigned(AInputData) then
  begin
    ImageDataHeader:=AInputData;
    if (ImageDataHeader.TimedDataHeader.DataHeader.Magic=16961)and(ImageDataHeader.TimedDataHeader.DataHeader.Version=0)and(ImageDataHeader.ImageType=itBGR) then
    begin
      FLock.Enter;
      try
        tmpInput:=ImageDataHeader.Data;
        tmpPicture:=PImageDataHeader(FPicture).Data;
        for y:=0 to ImageDataHeader.Height-1 do
        begin
          dstY:=y+ImageDataHeader.Top;
          if dstY<PImageDataHeader(FPicture).Height then
          begin
            if dstY>=0 then  //игнорировать всё что выше картинки
            begin
              if ImageDataHeader.Left>0 then  //если левый край внутри картинки
              begin
                OffsetFrom:=y*ImageDataHeader.Width*3;
                OffsetTo:=(PImageDataHeader(FPicture).Width*dstY+ImageDataHeader.Left)*3;
                CopyCount:=ImageDataHeader.Width*3;
              end
              else  //если левый край снаружи картинки
              begin
                  OffsetFrom:=(y*ImageDataHeader.Width-ImageDataHeader.Left)*3;
                  OffsetTo:=PImageDataHeader(FPicture).Width*dstY*3;
                  CopyCount:=(ImageDataHeader.Width-ImageDataHeader.Left)*3;
              end;
              //если правый край снаружи картинки
              if ImageDataHeader.Left+ImageDataHeader.Width>PImageDataHeader(FPicture).Width then
                  CopyCount:=CopyCount-(ImageDataHeader.Left+ImageDataHeader.Width-PImageDataHeader(FPicture).Width)*3;
              move(tmpInput[OffsetFrom],tmpPicture[OffsetTo],CopyCount);
            end;
          end
          else  //игнорировать всё что ниже картинки
            break;
        end;
        PImageDataHeader(FPicture).TimedDataHeader.Time:=ImageDataHeader.TimedDataHeader.Time;
      finally
        FLock.Leave;
      end;
    end;
  end;
end;

end.
