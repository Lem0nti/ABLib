unit ABL.Render.Drawer;

interface

uses
  ABL.Core.BaseObject, ABL.VS.VSTypes, SyncObjs, Types, ABL.Core.Debug, SysUtils, Graphics,
  {$IFDEF UNIX}Xlib, X, gtk2{$ELSE}Windows{$ENDIF}, DateUtils;

type
  {$IFDEF UNIX}
  TDrawNotify = procedure (Display: PDisplay; Drawable: TDrawable; GC: TGC) of object;
  {$ELSE}
  TDrawNotify = procedure (DC: HDC; Width, Height: integer) of object;
  {$ENDIF}

  TDrawer=class(TBaseObject)
  private
    FCameraName: string;
    FFocusRect: TRect;
    FHandle: THandle;
    Font: TFont;
    FOnDraw: TDrawNotify;
    FShowTime: boolean;
    FVerticalMirror: boolean;
    LastPicture: Pointer;
    SkipThru: TDateTime;
    {$IFDEF UNIX}
    FDisplay: PDisplay;
    FImage: PXImage;
    {$ENDIF}
    ScaledBuff: Pointer;
    function GetShowTime: boolean;
    procedure SetShowTime(const Value: boolean);
    function GetVerticalMirror: boolean;
    procedure SetVerticalMirror(const Value: boolean);
    function GetFocusRect: TRect;
    procedure SetFocusRect(const Value: TRect);
    function GetCameraName: string;
    procedure SetCameraName(const Value: string);
    function GetOnDraw: TDrawNotify;
    procedure SetOnDraw(const Value: TDrawNotify);
  public
    constructor Create(AName: string = ''); reintroduce;
    destructor Destroy; override;
    function Draw(ImageData: PImageDataHeader): integer;
    procedure SetHandle(const Value: THandle);
    property CameraName: string read GetCameraName write SetCameraName;
    property FocusRect: TRect read GetFocusRect write SetFocusRect;
    property OnDraw: TDrawNotify read GetOnDraw write SetOnDraw;
    property ShowTime: boolean read GetShowTime write SetShowTime;
    property VerticalMirror: boolean read GetVerticalMirror write SetVerticalMirror;
  end;

implementation

{ TDrawer }

constructor TDrawer.Create(AName: string);
var
  screen: integer;
  visual: PVisual;
begin
  inherited Create(AName);
  SkipThru:=0;
  LastPicture:=nil;
  FVerticalMirror:=true;
  FHandle:=0;
  FShowTime:=false;
  GetMem(ScaledBuff,16000000);
  {$IFDEF UNIX}
  FDisplay:=XOpenDisplay(nil);
  screen:=DefaultScreen(FDisplay);
  visual:=DefaultVisual(FDisplay,screen);
  FImage:=XCreateImage(FDisplay,visual,24,ZPixmap,0,PChar(scaledBuff),100,100,32,0);
  {$ELSE}
  Font:=TFont.Create;
  {$ENDIF}
end;

destructor TDrawer.Destroy;
begin
  {$IFDEF UNIX}
  XCloseDisplay(FDisplay);
  {$ELSE}
  Font.Free;
  {$ENDIF}
  FreeMem(ScaledBuff);
  inherited;
end;

function TDrawer.Draw(ImageData: PImageDataHeader): integer;
var
  {$IFDEF UNIX}
  attr: PXWindowAttributes;
  tmpStatus: integer;
  gc: TGC;
  Widget: PGtkWidget;
  {$ELSE}
  bmpinfo: BITMAPINFO;
  drawDC: HDC;
  {$ENDIF}
  ppRect: TRect;
  x,y,Offset,OffsetFrom,RectWidth,RectHeight,tmpX,tmpY: integer;
  wh,hh: Real;
  lRatio: Double;
  src: TRect;
  OutText: string;
  ByteFrom,ByteTo: PByte;
begin
  result:=0;
  if FHandle>0 then
  begin
    try
      {$IFDEF UNIX}
      FImage^.bitmap_unit:= 24;
      FImage^.bitmap_pad:= 24;
      FImage^.depth:= 24;
      FImage^.bits_per_pixel:= 24;
      {$ELSE}
      ZeroMemory(@bmpinfo,sizeof(bmpinfo));
      bmpinfo.bmiHeader.biSize:=sizeof(bmpinfo.bmiHeader);
      bmpinfo.bmiHeader.biPlanes:=1;
      bmpinfo.bmiHeader.biBitCount:=24;
      bmpinfo.bmiHeader.biCompression:=BI_RGB;
      {$ENDIF}
      FLock.Enter;
      try
        {$IFDEF UNIX}
        Widget:=PGtkWidget(FHandle);
        if Widget^.window = nil then
          exit;
        RectWidth:=Widget^.allocation.width;
        RectHeight:=Widget^.allocation.height;
        if RectWidth>2560 then
            RectWidth:=2560
        else if RectWidth mod 4>0 then
            RectWidth:=RectWidth+4-RectWidth mod 4;
        if RectHeight>1440 then
            RectHeight:=1440;
        FImage^.width:=RectWidth;
        FImage^.height:=RectHeight;
        FImage^.bytes_per_line:=RectWidth*3;
        {$ELSE}
        GetWindowRect(FHandle,ppRect);
        RectWidth:=ppRect.Width;
        RectHeight:=ppRect.Height;
        if RectWidth>2560 then
            RectWidth:=2560
        else if RectWidth mod 4>0 then
            RectWidth:=RectWidth+4-RectWidth mod 4;
        if RectHeight>1440 then
            RectHeight:=1440;
        {$ENDIF}
        if (RectWidth>0) and (RectHeight>0) then
        begin
          while RectWidth mod 4 > 0 do
            RectWidth:=RectWidth+1;        
          wh:=ImageData^.Width/RectWidth;
          hh:=ImageData^.Height/RectHeight;
          if (ImageData^.Width<>RectWidth) or (ImageData^.Height<>RectHeight) then
          begin
            Offset:=0;
            FillChar(scaledBuff^,255,RectWidth*RectHeight*3);
            ByteFrom:=ImageData^.Data;
            ByteTo:=scaledBuff;
            for y := 0 to RectHeight-1 do
              for x := 0 to RectWidth-1 do
              begin
                tmpY:=Round(hh*y);
                if tmpY>ImageData^.Height-1 then
                    tmpY:=ImageData^.Height-1;
                tmpX:=Round(wh*x);
                if tmpX>ImageData^.Width-1 then
                    tmpX:=ImageData^.Width-1;
                OffsetFrom:=(tmpY*ImageData^.Width+tmpX)*3;
                Move(PByte(NativeUInt(ByteFrom)+OffsetFrom)^,PByte(NativeUInt(ByteTo)+Offset*3)^,3);
                inc(Offset);
              end;
            ImageData^.Width:=ppRect.Width;
            ImageData^.Height:=ppRect.Height;
          end
          else
            Move(ImageData^.Data^,scaledBuff^,RectWidth*RectHeight*3);
          {$IFDEF UNIX}
          XSynchronize(FDisplay, true);
          gc:=XCreateGC(FDisplay, FHandle, 0,nil);
          XPutImage(FDisplay, FHandle, gc, FImage, 0, 0, 0, 0, RectWidth, RectHeight);
          if assigned(FOnDraw) then
            FOnDraw(FDisplay, FHandle, gc);
          XFreeGC(FDisplay, gc);
          {$ELSE}
          bmpinfo.bmiHeader.biWidth:=ImageData^.Width;
          bmpinfo.bmiHeader.biSizeImage:=ImageData^.Width*ImageData^.Height*3;
          if ImageData^.FlipMarker then
            bmpinfo.bmiHeader.biHeight:=-ImageData^.Height
          else
            bmpinfo.bmiHeader.biHeight:=ImageData^.Height;
          drawDC:=GetDC(FHandle);
          try
            StretchDIBits(drawDC,0,0,ppRect.Width,ppRect.Height,0,0,ImageData^.Width,ImageData^.Height,ImageData^.Data,bmpinfo,DIB_RGB_COLORS,SRCCOPY);
            SetBkMode(drawDC,TRANSPARENT);
            lRatio:=1080/ppRect.Width;
            // Динамический подбор размера шрифта к разрешению экрана
            Font.Size:= Round(28/lRatio);
            Font.Color:=clLime;
            SetTextColor(drawDC,Font.Color);
            SelectObject(drawDC,Font.Handle);
            src.Top := Round(10/lRatio);
            src.Left:= Round(10/lRatio);
            src.Bottom:=ppRect.Height;
            src.Right:=ppRect.Width-src.Left;
            if FCameraName<>'' then
              DrawText(drawDC,PChar(FCameraName),Length(FCameraName),src,DT_NOCLIP or DT_TOP or DT_SINGLELINE or DT_LEFT);
            if FShowTime then
            begin
              if (ImageData^.TimedDataHeader.Time>2641367261872)or(ImageData^.TimedDataHeader.Time<0) then
                SendErrorMsg('TDrawer.Draw 131: invalid time - '+IntToStr(ImageData^.TimedDataHeader.Time))
              else
              begin
                OutText:=DateTimeToStr(IncMilliSecond(UnixDateDelta,ImageData^.TimedDataHeader.Time));
                DrawText(drawDC,PChar(OutText),Length(OutText),src,DT_NOCLIP or DT_TOP or DT_SINGLELINE or DT_RIGHT);
              end;
            end;
            if FFocusRect.Left>0 then
              DrawFocusRect(drawDC,FFocusRect);
            if assigned(FOnDraw) then
              FOnDraw(drawDC,ppRect.Width,ppRect.Height);
          finally
            ReleaseDC(FHandle,drawDC);
          end;
          {$ENDIF}
        end;
      finally
        FLock.Leave;
      end;
    except on e: Exception do
      begin
        result:=-1;
        SendErrorMsg('TDrawer('+FName+').Draw 141: '+e.ClassName+' - '+e.Message);
      end;
    end;
  end;
end;

function TDrawer.GetCameraName: string;
begin
  FLock.Enter;
  try
    result:=FCameraName;
  finally
    FLock.Leave;
  end;
end;

function TDrawer.GetFocusRect: TRect;
begin
  FLock.Enter;
  try
    result:=FFocusRect;
  finally
    FLock.Leave;
  end;
end;

function TDrawer.GetOnDraw: TDrawNotify;
begin
  FLock.Enter;
  try
    result:=FOnDraw;
  finally
    FLock.Leave;
  end;
end;

function TDrawer.GetShowTime: boolean;
begin
  FLock.Enter;
  try
    result:=FShowTime;
  finally
    FLock.Leave;
  end;
end;

function TDrawer.GetVerticalMirror: boolean;
begin
  FLock.Enter;
  try
    result:=FVerticalMirror;
  finally
    FLock.Leave;
  end;
end;

procedure TDrawer.SetCameraName(const Value: string);
begin
  FLock.Enter;
  try
    FCameraName:=Value;
  finally
    FLock.Leave;
  end;
end;

procedure TDrawer.SetFocusRect(const Value: TRect);
begin
  FLock.Enter;
  try
    FFocusRect:=Value;
  finally
    FLock.Leave;
  end;
end;

procedure TDrawer.SetHandle(const Value: THandle);
begin
  FLock.Enter;
  try
    FHandle:=Value;
  finally
    FLock.Leave;
  end;
end;

procedure TDrawer.SetOnDraw(const Value: TDrawNotify);
begin
  FLock.Enter;
  try
    FOnDraw:=Value;
  finally
    FLock.Leave;
  end;
end;

procedure TDrawer.SetShowTime(const Value: boolean);
begin
  FLock.Enter;
  try
    FShowTime:=Value;
  finally
    FLock.Leave;
  end;
end;

procedure TDrawer.SetVerticalMirror(const Value: boolean);
begin
  FLock.Enter;
  try
    FVerticalMirror:=Value;
  finally
    FLock.Leave;
  end;
end;

end.
