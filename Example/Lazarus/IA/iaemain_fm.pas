unit iaeMain_FM;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls;

type

  { TMainFM }

  TMainFM = class(TForm)
    bGo: TButton;
    eLink: TEdit;
    Panel2: TPanel;
    pnlLeft: TPanel;
    pnlLeftBottom: TPanel;
    pnlLeftTop: TPanel;
    pnlRightBottom: TPanel;
    pnlRightTop: TPanel;
    pnlTop: TPanel;
    procedure bGoClick(Sender: TObject);
    procedure eLinkChange(Sender: TObject);
    procedure eLinkKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private

  public

  end;

var
  MainFM: TMainFM;

implementation

{$R *.lfm}

{ TMainFM }

procedure TMainFM.bGoClick(Sender: TObject);
begin
  if bGo.Caption='Старт' then
  begin
    if not assigned(VideoDecoder) then
      VideoDecoder:=TVideoDecoder.Create(ThreadController.QueueByName('Decoder'),ThreadController.QueueByName('BGR'),AV_CODEC_ID_H264,'VideoDecoder');
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
    DecodedMultiplier.AddReceiver(RenderLeftTop.InputQueue);
  end;
end;

procedure TMainFM.eLinkChange(Sender: TObject);
begin
  with TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
  try
    WriteString('MAIN','Link',eLink.Text);
  finally
    Free;
  end;
end;

procedure TMainFM.eLinkKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key=13 then
    bGo.Click;
end;

procedure TMainFM.FormCreate(Sender: TObject);
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

procedure TMainFM.FormDestroy(Sender: TObject);
begin
  if assigned(RTSPReceiver) then
    FreeAndNil(RTSPReceiver);
  if assigned(VideoDecoder) then
    FreeAndNil(VideoDecoder);
end;

procedure TMainFM.FormResize(Sender: TObject);
begin
  pnlLeft.Width:=ClientWidth div 2;
  pnlLeftTop.Height:=(ClientHeight-pnlTop.Height) div 2;
  pnlRightTop.Height:=(ClientHeight-pnlTop.Height) div 2;
end;

end.

