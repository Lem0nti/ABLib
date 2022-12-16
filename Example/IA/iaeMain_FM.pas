unit iaeMain_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, ABL.VS.VideoDecoder, ABL.Render.DirectRender,
  ABL.Core.ThreadController, ABL.VS.RTSPReceiver, ABL.VS.FFMPEG, ABL.Core.QueueMultiplier, IniFiles;

type
  TMinFM = class(TForm)
    pnlLeft: TPanel;
    pnlLeftTop: TPanel;
    pnlLeftBottom: TPanel;
    Panel2: TPanel;
    pnlRightTop: TPanel;
    pnlRightBottom: TPanel;
    pnlTop: TPanel;
    eLink: TEdit;
    bGo: TButton;
    procedure bGoClick(Sender: TObject);
    procedure eLinkChange(Sender: TObject);
    procedure eLinkKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    DecodedMultiplier: TQueueMultiplier;
    RenderLeftTop: TDirectRender;
    RTSPReceiver: TRTSPReceiver;
    VideoDecoder: TVideoDecoder;
  public
    { Public declarations }
  end;

var
  MinFM: TMinFM;

implementation

{$R *.dfm}

procedure TMinFM.bGoClick(Sender: TObject);
begin
  if bGo.Caption='Старт' then
  begin
    if not assigned(VideoDecoder) then
      VideoDecoder:=TVideoDecoder.Create(ThreadController.QueueByName('Decoder'),ThreadController.QueueByName('BGR'),AV_CODEC_ID_H264,'Decoder');
    if not assigned(RTSPReceiver) then
      RTSPReceiver:=TRTSPReceiver.Create(VideoDecoder.InputQueue,'RTSPReceiver',eLink.Text);
    bGo.Caption:='Стоп';
  end
  else
  begin
    bGo.Caption:='Старт';
    if assigned(RTSPReceiver) then
      FreeAndNil(RTSPReceiver);
    if assigned(VideoDecoder) then
      FreeAndNil(VideoDecoder);
    exit;
  end;
  if not assigned(DecodedMultiplier) then
    DecodedMultiplier:=TQueueMultiplier.Create(VideoDecoder.OutputQueue,'DecodedMultiplier');
  if not assigned(RenderLeftTop) then
  begin
    RenderLeftTop:=TDirectRender.Create('RenderLeftTop');
    RenderLeftTop.Handle:=pnlLeftTop.Handle;
    //RenderLeftTop.OnDraw:=MainDraw;
    DecodedMultiplier.AddReceiver(RenderLeftTop.InputQueue);
  end;
end;

procedure TMinFM.eLinkChange(Sender: TObject);
begin
  with TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
    try
      WriteString('MAIN','Link',eLink.Text);
    finally
      Free;
    end;
end;

procedure TMinFM.eLinkKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=13 then
    bGo.Click;
end;

procedure TMinFM.FormCreate(Sender: TObject);
var
  AFMask,w: integer;
begin
  if System.CPUCount>2 then
  begin
    //значение маски=(2 в_степени <кол-во_процессоров> - 2)
    //(14 для 4 ядер; 62 для 6; 254 для 8 и т.д.)
    AFMask:=2;
    for w:=2 to System.CPUCount do
      AFMask:=AFMask*2;
    AFMask:=AFMask-2;
    SetProcessAffinityMask(GetCurrentProcess,AFMask);
  end;
  with TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
    try
      eLink.Text:=ReadString('MAIN','Link',eLink.Text);
    finally
      Free;
    end;
end;

procedure TMinFM.FormDestroy(Sender: TObject);
begin
  if assigned(RTSPReceiver) then
    FreeAndNil(RTSPReceiver);
end;

procedure TMinFM.FormResize(Sender: TObject);
begin
  pnlLeft.Width:=ClientWidth div 2;
  pnlLeftTop.Height:=(ClientHeight-pnlTop.Height) div 2;
  pnlRightTop.Height:=(ClientHeight-pnlTop.Height) div 2;
end;

end.
