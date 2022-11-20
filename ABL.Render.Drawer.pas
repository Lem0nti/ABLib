unit ABL.Render.Drawer;

interface

uses
  ABL.Core.BaseObject, ABL.VS.VSTypes, SyncObjs, Types, ABL.Core.Debug, SysUtils, Graphics, Windows, DateUtils;

type
  TDrawNotify = procedure (DC: HDC; Width, Height: integer) of object;

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
    constructor Create(AHandle: THandle; AName: string = ''); reintroduce;
    destructor Destroy; override;
    function Draw(ImageData: TImageData): integer;
    procedure SetHandle(const Value: THandle);
    property CameraName: string read GetCameraName write SetCameraName;
    property FocusRect: TRect read GetFocusRect write SetFocusRect;
    property OnDraw: TDrawNotify read GetOnDraw write SetOnDraw;
    property ShowTime: boolean read GetShowTime write SetShowTime;
    property VerticalMirror: boolean read GetVerticalMirror write SetVerticalMirror;
  end;

implementation

{ TDrawer }

constructor TDrawer.Create(AHandle: THandle; AName: string);
begin
  inherited Create(AName);
  SkipThru:=0;
  LastPicture:=nil;
  FVerticalMirror:=true;
  SetHandle(AHandle);
  FShowTime:=false;
  Font:=TFont.Create;
end;

destructor TDrawer.Destroy;
begin
  Font.Free;
  inherited;
end;

function TDrawer.Draw(ImageData: TImageData): integer;
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
    try
      ZeroMemory(@bmpinfo,sizeof(bmpinfo));
      bmpinfo.bmiHeader.biSize:=sizeof(bmpinfo.bmiHeader);
      bmpinfo.bmiHeader.biPlanes:=1;
      bmpinfo.bmiHeader.biBitCount:=24;
      bmpinfo.bmiHeader.biCompression:=BI_RGB;
      FLock.Enter;
      try
        GetWindowRect(FHandle,ppRect);
        if (ppRect.Width>0) and (ppRect.Height>0) then
        begin
          while ppRect.Width mod 4 > 0 do
            ppRect.Width:=ppRect.Width+1;
          if (ImageData.ImageDataHeader.Width>ppRect.Width) or (ImageData.ImageDataHeader.Height>ppRect.Height) then
          begin
            wh:=ImageData.ImageDataHeader.Width/ppRect.Width;
            hh:=ImageData.ImageDataHeader.Height/ppRect.Height;
            Offset:=0;
            for y := 0 to ppRect.Height-1 do
              for x := 0 to ppRect.Width-1 do
              begin
                Move(PByte(NativeUInt(ImageData.Data)+(Round(y*hh)*ImageData.ImageDataHeader.Width+Round(x*wh))*3)^,
                    PByte(NativeUInt(ImageData.Data)+Offset*3)^,3);
                inc(Offset);
              end;
            ImageData.ImageDataHeader.Width:=ppRect.Width;
            ImageData.ImageDataHeader.Height:=ppRect.Height;
          end;
          bmpinfo.bmiHeader.biWidth:=ImageData.ImageDataHeader.Width;
          bmpinfo.bmiHeader.biSizeImage:=ImageData.ImageDataHeader.Width*ImageData.ImageDataHeader.Height*3;
          if ImageData.ImageDataHeader.FlipMarker then
            bmpinfo.bmiHeader.biHeight:=-ImageData.ImageDataHeader.Height
          else
            bmpinfo.bmiHeader.biHeight:=ImageData.ImageDataHeader.Height;
          drawDC:=GetDC(FHandle);
          try
            StretchDIBits(drawDC,0,0,ppRect.Width,ppRect.Height,0,0,ImageData.ImageDataHeader.Width,ImageData.ImageDataHeader.Height,ImageData.Data,
                bmpinfo,DIB_RGB_COLORS,SRCCOPY);
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
              DrawText(drawDC,FCameraName,Length(FCameraName),src,DT_NOCLIP or DT_TOP or DT_SINGLELINE or DT_LEFT);
            if FShowTime then
            begin
              if (ImageData.ImageDataHeader.TimedDataHeader.Time>2641367261872)or(ImageData.ImageDataHeader.TimedDataHeader.Time<0) then
                SendErrorMsg('TDrawer.Draw 124: invalid time - '+IntToStr(ImageData.ImageDataHeader.TimedDataHeader.Time))
              else
              begin
                OutText:=DateTimeToStr(IncMilliSecond(UnixDateDelta,ImageData.ImageDataHeader.TimedDataHeader.Time));
                DrawText(drawDC,OutText,Length(OutText),src,DT_NOCLIP or DT_TOP or DT_SINGLELINE or DT_RIGHT);
              end;
            end;
            if FFocusRect.Left>0 then
              DrawFocusRect(drawDC,FFocusRect);
            if assigned(FOnDraw) then
              FOnDraw(drawDC,ppRect.Width,ppRect.Height);
          finally
            ReleaseDC(FHandle,drawDC);
          end;
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
