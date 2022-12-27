unit iaeMain_FM;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, ABL.IA.ImageConverter, IniFiles, Types,
  ABL.IA.Closing, ABL.Core.QueueMultiplier, ABL.IA.ImageCutter, ABL.IA.LocalBinarization, ABL.VS.FFMPEG, {$IFDEF WINDOWS}Windows,{$ENDIF}
  ABL.IA.Opening, ABL.Render.DirectRender, ABL.VS.RTSPReceiver, ABL.VS.VideoDecoder, ABL.Core.ThreadController;

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
    procedure pnlLeftTopMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pnlLeftTopMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure pnlLeftTopMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    BinConverter,OpenConverter,CloseConverter: TImageConverter;
    Closing: TClosing;
    DecodedMultiplier,BinaryMultiplier: TQueueMultiplier;
    FFocusRect: TRect;
    ImageCutter: TImageCutter;
    LocalBinarization: TLocalBinarization;
    Opening: TOpening;
    RenderLeftTop,RenderRightTop,RenderLeftBottom,RenderRightBottom: TDirectRender;
    RTSPReceiver: TRTSPReceiver;
    VideoDecoder: TVideoDecoder;
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
  //exit;
  if not assigned(ImageCutter) then
  begin
    ImageCutter:=TImageCutter.Create(ThreadController.QueueByName('Cutter'),'ImageCutter');
    DecodedMultiplier.AddReceiver(ImageCutter.InputQueue);
  end;
  if not assigned(LocalBinarization) then
  begin
    LocalBinarization:=TLocalBinarization.Create(ThreadController.QueueByName('BinarizationInput'),ThreadController.QueueByName('BinarizationOutput'),'LocalBinarization');
    ImageCutter.AddReceiver(LocalBinarization.InputQueue,Types.Rect(3000,3000,4000,4000));
  end;
  if not assigned(BinaryMultiplier) then
    BinaryMultiplier:=TQueueMultiplier.Create(LocalBinarization.OutputQueue,'BinaryMultiplier');
  if not assigned(RenderRightTop) then
  begin
    RenderRightTop:=TDirectRender.Create('RenderRightTop');
    RenderRightTop.Handle:=pnlRightTop.Handle;
  end;
  if not assigned(BinConverter) then
  begin
    BinConverter:=TImageConverter.Create(ThreadController.QueueByName('BinConverterInput'),RenderRightTop.InputQueue,'BinConverter');
    BinaryMultiplier.AddReceiver(BinConverter.InputQueue);
  end;
  if not assigned(Opening) then
  begin
    Opening:=TOpening.Create(ThreadController.QueueByName('OpeningInput'),ThreadController.QueueByName('OpeningOutput'),'Opening');
    BinaryMultiplier.AddReceiver(Opening.InputQueue);
  end;
  if not assigned(RenderLeftBottom) then
  begin
    RenderLeftBottom:=TDirectRender.Create('RenderLeftBottom');
    RenderLeftBottom.Handle:=pnlLeftBottom.Handle;
  end;
  if not assigned(OpenConverter) then
    OpenConverter:=TImageConverter.Create(Opening.OutputQueue,RenderLeftBottom.InputQueue,'OpenConverter');
  if not assigned(Closing) then
  begin
    Closing:=TClosing.Create(ThreadController.QueueByName('ClosingInput'),ThreadController.QueueByName('ClosingOutput'),'Closing');
    BinaryMultiplier.AddReceiver(Closing.InputQueue);
  end;
  if not assigned(RenderRightBottom) then
  begin
    RenderRightBottom:=TDirectRender.Create('RenderRightBottom');
    RenderRightBottom.Handle:=pnlRightBottom.Handle;
  end;
  if not assigned(CloseConverter) then
    CloseConverter:=TImageConverter.Create(Closing.OutputQueue,RenderRightBottom.InputQueue,'CloseConverter');
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
{$IFDEF WINDOWS}
var
  AFMask,w: integer;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
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
  {$ENDIF}
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

procedure TMainFM.pnlLeftTopMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
    FFocusRect.TopLeft:=Types.Point(X,Y);
end;

procedure TMainFM.pnlLeftTopMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if ssLeft in Shift then
  begin
    FFocusRect.BottomRight:=Types.Point(X,Y);
    RenderLeftTop.Drawer.FocusRect:=FFocusRect;
  end;
end;

procedure TMainFM.pnlLeftTopMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
  begin
    ImageCutter.UpdateReceiver(LocalBinarization.InputQueue,Types.Rect(Round(FFocusRect.Left/pnlLeftTop.Width*10000),Round(FFocusRect.Top/pnlLeftTop.Height*10000),
        Round(FFocusRect.Right/pnlLeftTop.Width*10000),Round(FFocusRect.Bottom/pnlLeftTop.Height*10000)));
  end;
  RenderLeftTop.Drawer.FocusRect:=Types.Rect(0,0,0,0);
end;

end.

