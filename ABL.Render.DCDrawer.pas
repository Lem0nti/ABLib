unit ABL.Render.DCDrawer;

interface

uses
  ABL.Render.Drawer, ABL.VS.VSTypes, Windows, ABL.Core.Debug, SysUtils, SyncObjs, Graphics, DateUtils, Types;

type
  TDCDrawer=class(TDrawer)
  private
    FHandle: THandle;
    Font: TFont;
    SkipThru: TDateTime;
    LastPicture: PDecodedFrame;
  public
    constructor Create(AHandle: THandle; AName: string = ''); reintroduce;
    destructor Destroy; override;
    function Draw(ADecodedFrame: PDecodedFrame): integer; override;
    procedure SetHandle(const Value: THandle; Width: integer = 0; Height: integer=0);
  end;

implementation

{ TDCDrawer }

constructor TDCDrawer.Create(AHandle: THandle; AName: string);
begin
  inherited Create(AName);
  SkipThru:=0;
  LastPicture:=nil;
  FVerticalMirror:=true;
  SetHandle(AHandle);
  FShowTime:=false;
  Font:=TFont.Create;
end;

destructor TDCDrawer.Destroy;
begin
  Font.Free;
  inherited;
end;

function TDCDrawer.Draw(ADecodedFrame: PDecodedFrame): integer;
var
  bmpinfo: BITMAPINFO;
  drawDC: HDC;
  ppRect: TRect;
  x,y,Offset: integer;
  wh,hh: Real;
  lRatio: Double;
  src: TRect;
  OutText: string;
begin
  result:=0;
  if FHandle>0 then
  begin
    ZeroMemory(@bmpinfo,sizeof(bmpinfo));
    bmpinfo.bmiHeader.biSize:=sizeof(bmpinfo.bmiHeader);
    bmpinfo.bmiHeader.biPlanes:=1;
    bmpinfo.bmiHeader.biBitCount:=24;
    bmpinfo.bmiHeader.biCompression:=BI_RGB;
    FLock.Enter;
    try
      GetWindowRect(FHandle,ppRect);
      while ppRect.Width mod 4 > 0 do
        ppRect.Width:=ppRect.Width+1;
      if (ADecodedFrame.Width>ppRect.Width) or (ADecodedFrame.Height>ppRect.Height) then
      begin
        wh:=ADecodedFrame.Width/ppRect.Width;
        hh:=ADecodedFrame.Height/ppRect.Height;
        Offset:=0;
        for y := 0 to ppRect.Height-1 do
          for x := 0 to ppRect.Width-1 do
          begin
            Move(PByte(NativeUInt(ADecodedFrame.Data)+(Round(y*hh)*ADecodedFrame.Width+Round(x*wh))*3)^,
                PByte(NativeUInt(ADecodedFrame.Data)+Offset*3)^,3);
            inc(Offset);
          end;
        ADecodedFrame.Width:=ppRect.Width;
        ADecodedFrame.Height:=ppRect.Height;
      end;
      bmpinfo.bmiHeader.biWidth:=ADecodedFrame.Width;
      bmpinfo.bmiHeader.biSizeImage:=ADecodedFrame.Width*ADecodedFrame.Height*3;
      bmpinfo.bmiHeader.biHeight:=-ADecodedFrame.Height;
      drawDC:=GetDC(FHandle);
      try
        StretchDIBits(drawDC,0,0,ppRect.Width,ppRect.Height,0,0,ADecodedFrame.Width,ADecodedFrame.Height,ADecodedFrame.Data,
            bmpinfo,DIB_RGB_COLORS,SRCCOPY);
        if FShowTime then
        begin
          if (ADecodedFrame.Time>2641367261872)or(ADecodedFrame.Time<0) then
            SendErrorMsg('TDCDrawer.Draw 92: invalid time - '+IntToStr(ADecodedFrame.Time))
          else
          begin
            lRatio:=1080/ppRect.Width;
            // Динамический подбор размера шрифта к разрешению экрана
            Font.Size:= Round(28/lRatio);
            Font.Color:=clLime;
            // Динамический подбор координат, относительно разрешения экрана
            src.Top := Round(8/lRatio);
            src.Left:= Round(8/lRatio);
            src.Bottom:=ppRect.Height;
            src.Right:=ppRect.Width-src.Left;
            SetBkMode(drawDC,TRANSPARENT);
            SetTextColor(drawDC,Font.Color);
            SelectObject(drawDC,Font.Handle);
            try
              OutText:=DateTimeToStr(IncMilliSecond(UnixDateDelta,ADecodedFrame.Time));
              DrawText(drawDC,OutText,Length(OutText),src,DT_NOCLIP or DT_TOP or DT_SINGLELINE or DT_RIGHT);
            except on e: Exception do
              SendErrorMsg('TDCDrawer.Draw 111: '+e.ClassName+' - '+e.Message);
            end;
          end;
        end;
        if FFocusRect.Left>0 then
          DrawFocusRect(drawDC,FFocusRect);
      finally
        ReleaseDC(FHandle,drawDC);
      end;
    finally
      FLock.Leave;
    end;
  end;
end;

procedure TDCDrawer.SetHandle(const Value: THandle; Width, Height: integer);
begin
  FLock.Enter;
  try
    FHandle:=Value;
  finally
    FLock.Leave;
  end;
end;

end.
