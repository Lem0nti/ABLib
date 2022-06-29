unit eMain_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  ABL.IA.ImageCutter, ABL.IA.IfMotion, ABL.IA.LocalBinarization, ABL.IA.FindDark,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdGlobal, ABL.VS.RTSPReceiver, ABL.VS.FFMPEG,
  ABL.VS.DecodedMultiplier, ABL.IA.ImageConverter, ABL.VS.DecodedItem, ABL.Core.BaseThread,
  ABL.Core.QueueMultiplier, ABL.Core.ThreadController, Vcl.ComCtrls, ABL.Render.DirectRender, ABL.IA.ImageResize,
  Vcl.StdCtrls, eDirect_Cl, eMessage, eTimer_Cl, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  Vcl.ExtCtrls, ABL.IO.TCPReader, eTCPToLog_Cl, Vcl.Buttons, ABL.VS.VideoDecoder, ABL.Core.ThreadQueue;

type
  TMainFM = class(TForm)
    PageControl: TPageControl;
    tsCore: TTabSheet;
    bCreate: TButton;
    mCoreLog: TMemo;
    bSend: TButton;
    tsIO: TTabSheet;
    mIOLog: TMemo;
    leText: TLabeledEdit;
    bSendTCP: TButton;
    IdTCPClient: TIdTCPClient;
    tsVS_Render: TTabSheet;
    pnlVideo: TPanel;
    leRTSPLink: TLabeledEdit;
    bGo: TBitBtn;
    pnlLeftTop: TPanel;
    pnlRightTop: TPanel;
    pnlLeftBottom: TPanel;
    pnlRightBottom: TPanel;
    pnlRight: TPanel;
    pnlBottom: TPanel;
    procedure bCreateClick(Sender: TObject);
    procedure bSendClick(Sender: TObject);
    procedure bSendTCPClick(Sender: TObject);
    procedure leRTSPLinkKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure bGoClick(Sender: TObject);
    procedure pnlVideoResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pnlRightTopDblClick(Sender: TObject);
  private
    { Private declarations }
    Direct1,Direct2: TDirect;
    Timer1,Timer2: TABLTimer;
    Multiplier: TQueueMultiplier;
    TCPReader: TTCPReader;
    TCPToLog: TTCPToLog;
    RTSPReceiver: TRTSPReceiver;
    VideoDecoder: TVideoDecoder;
    Render,ResizeRender,LeftIfRender,RightIfRender,LocalRender,FindDarkRender: TDirectRender;
    DecodedMultiplier: TDecodedMultiplier;
    ImageResize: TImageResize;
    ImageCutter: TImageCutter;
    IfMotionLeft, IfMotionRight: TIfMotion;
    LocalBinarization: TLocalBinarization;
    FindDark: TFindDark;
    icLocalBinarization,icFindDark: TImageConverter;
    procedure ABLThreadExecute(var Message: TMessage); message WM_ABL_THREAD_EXECUTED;
    procedure Multiply(AInputData: Pointer; var AResultData: Pointer);
  public
    { Public declarations }
  end;

var
  MainFM: TMainFM;

implementation

{$R *.dfm}

procedure TMainFM.ABLThreadExecute(var Message: TMessage);
var
  tmpString: PString;
begin
  tmpString:=PString(Message.WParam);
  if PageControl.ActivePage=tsCore then
    mCoreLog.Lines.Add(tmpString^)
  else
    mIOLog.Lines.Add(tmpString^);
  dispose(tmpString);
end;

procedure TMainFM.bCreateClick(Sender: TObject);
begin
  Direct1:=TDirect.Create(ThreadController.QueueByName('Direct1_Input'),ThreadController.QueueByName('Direct1_Output'),'Direct1');
  Direct1.Active:=true;
  Timer1:=TABLTimer.Create(ThreadController.QueueByName('Direct1_Output'),ThreadController.QueueByName('Timer1_Output'),'Timer1');
  Timer1.Active:=true;
  Multiplier:=TQueueMultiplier.Create(ThreadController.QueueByName('Timer1_Output'),'Multiplier');
  Multiplier.OnMultiply:=Multiply;
  Multiplier.AddReceiver(ThreadController.QueueByName('Direct2_Input'));
  Multiplier.AddReceiver(ThreadController.QueueByName('Timer2_Input'));
  Multiplier.Active:=true;
  Direct2:=TDirect.Create(ThreadController.QueueByName('Direct2_Input'),nil,'Direct2');
  Direct2.Active:=true;
  Timer2:=TABLTimer.Create(ThreadController.QueueByName('Timer2_Input'),nil,'Timer2');
  Timer2.Active:=true;
  MSGReceiver:=Handle;
end;

procedure TMainFM.bGoClick(Sender: TObject);
begin
  if assigned(RTSPReceiver) then
    RTSPReceiver.ConnectionString:=leRTSPLink.Text
  else
    RTSPReceiver:=TRTSPReceiver.Create(TThreadQueue(ThreadController.QueueByName('Receiver_Output')),'RTSPReceiver',leRTSPLink.Text);
  if not assigned(VideoDecoder) then
    VideoDecoder:=TVideoDecoder.Create(ThreadController.QueueByName('Receiver_Output'),ThreadController.QueueByName('Decoder_Output'),
        AV_CODEC_ID_H264,'VideoDecoder');
  if not assigned(DecodedMultiplier) then
    DecodedMultiplier:=TDecodedMultiplier.Create(ThreadController.QueueByName('Decoder_Output'),'DecodedMultiplier');
  if not assigned(Render) then
  begin
    Render:=TDirectRender.Create('Render');
    Render.Handle:=pnlLeftTop.Handle;
    DecodedMultiplier.AddReceiver(Render.InputQueue);
  end;
  if not assigned(ImageResize) then
  begin
    ImageResize:=TImageResize.Create(ThreadController.QueueByName('Resize_Input'),nil);
    ImageResize.SetSize(320,240);
    DecodedMultiplier.AddReceiver(ImageResize.InputQueue);
  end;
  //ресайз - справа-сверху
  if not assigned(ResizeRender) then
  begin
    ResizeRender:=TDirectRender.Create('ResizeRender');
    ResizeRender.Handle:=pnlRightTop.Handle;
    ImageResize.SetOutputQueue(ResizeRender.InputQueue);
  end;
  if not assigned(ImageCutter) then
  begin
    ImageCutter:=TImageCutter.Create(ThreadController.QueueByName('Cutter_Input'));
    DecodedMultiplier.AddReceiver(ImageCutter.InputQueue);
  end;
  if not assigned(IfMotionLeft) then
  begin
    IfMotionLeft:=TIfMotion.Create(ThreadController.QueueByName('IfMotionLeft_Input'),nil);
    ImageCutter.AddReceiver(IfMotionLeft.InputQueue,Rect(6000,1000,9000,4000));
  end;
  if not assigned(IfMotionRight) then
  begin
    IfMotionRight:=TIfMotion.Create(ThreadController.QueueByName('IfMotionRight_Input'),nil);
    ImageCutter.AddReceiver(IfMotionRight.InputQueue,Rect(1000,6000,4000,9000));
  end;
  //куттер+ифмоушн - снизу
  if not assigned(LeftIfRender) then
  begin
    LeftIfRender:=TDirectRender.Create('LeftIfRender');
    LeftIfRender.Handle:=pnlLeftBottom.Handle;
    IfMotionLeft.SetOutputQueue(LeftIfRender.InputQueue);
  end;
  if not assigned(RightIfRender) then
  begin
    RightIfRender:=TDirectRender.Create('RightIfRender');
    RightIfRender.Handle:=pnlBottom.Handle;
    IfMotionRight.SetOutputQueue(RightIfRender.InputQueue);
  end;
  if not assigned(LocalBinarization) then
  begin
    LocalBinarization:=TLocalBinarization.Create(TDecodedItem.Create('LocalBinarization_Input'),ThreadController.QueueByName('LocalBinarization_Output'),'LocalBinarization');
    DecodedMultiplier.AddReceiver(LocalBinarization.InputQueue);
  end;
  if not assigned(icLocalBinarization) then
    icLocalBinarization:=TImageConverter.Create(ThreadController.QueueByName('LocalBinarization_Output'),nil,'icLocalBinarization');
  if not assigned(LocalRender) then
  begin
    LocalRender:=TDirectRender.Create('LocalRender');
    LocalRender.Handle:=pnlRight.Handle;
    icLocalBinarization.SetOutputQueue(LocalRender.InputQueue);
  end;
  if not assigned(FindDark) then
  begin
    FindDark:=TFindDark.Create(TDecodedItem.Create('FindDark_Input'),TDecodedItem.Create('FindDark_Output'),'FindDark');
    DecodedMultiplier.AddReceiver(FindDark.InputQueue);
  end;
  if not assigned(icFindDark) then
    icFindDark:=TImageConverter.Create(FindDark.OutputQueue,nil,'icFindDark');
  if not assigned(FindDarkRender) then
  begin
    FindDarkRender:=TDirectRender.Create('FindDarkRender');
    FindDarkRender.Handle:=pnlRightBottom.Handle;
    icFindDark.SetOutputQueue(FindDarkRender.InputQueue);
  end;
end;

procedure TMainFM.bSendClick(Sender: TObject);
var
  tmpInteger: PInteger;
  q: integer;
begin
  for q := 1 to 100 do
  begin
    New(tmpInteger);
    ThreadController.QueueByName('Direct1_Input').Push(tmpInteger);
  end;
end;

procedure TMainFM.bSendTCPClick(Sender: TObject);
var
  idBytes: TidBytes;
  tmpString: AnsiString;
begin
  if not assigned(TCPReader) then
  begin
    TCPReader:=TTCPReader.Create(ThreadController.QueueByName('TCPReader_Output'));
    TCPReader.Port:=12345;
    TCPReader.Active:=true;
    TCPToLog:=TTCPToLog.Create(ThreadController.QueueByName('TCPReader_Output'),nil);
    TCPToLog.Active:=true;
  end;
  MSGReceiver:=Handle;
  tmpString:=AnsiString(leText.Text);
  IdTCPClient.Connect;
  SetLength(idBytes,length(tmpString));
  move(tmpString[1],idBytes[0],length(tmpString));
  IdTCPClient.IOHandler.Write(idBytes);
  IdTCPClient.Disconnect;
end;

procedure TMainFM.FormDestroy(Sender: TObject);
begin
  if assigned(RTSPReceiver) then
    RTSPReceiver.Free;
  if assigned(VideoDecoder) then
    VideoDecoder.Free;
  if assigned(DecodedMultiplier) then
  begin
    DecodedMultiplier.Stop;
    Sleep(100);
    DecodedMultiplier.Free;
  end;
  if assigned(LocalBinarization) then
  begin
    LocalBinarization.Stop;
    Sleep(100);
    LocalBinarization.Free;
  end;
  if assigned(FindDark) then
  begin
    FindDark.Stop;
    Sleep(100);
    FindDark.Free;
  end;
end;

procedure TMainFM.leRTSPLinkKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=13 then
    bGo.Click;
end;

procedure TMainFM.Multiply(AInputData: Pointer; var AResultData: Pointer);
var
  tmpString: PString;
begin
  New(tmpString);
  setstring(tmpString^, PChar(PString(AInputData)^), length(PString(AInputData)^));
  AResultData:=tmpString;
end;

procedure TMainFM.pnlRightTopDblClick(Sender: TObject);
var
  MainRender,SubRender: TDirectRender;
  Thread: TBaseThread;
begin
  MainRender:=nil;
  SubRender:=nil;
  for Thread in ThreadList do
    if Thread.ClassNameIs('TDirectRender') then
    begin
      if TDirectRender(Thread).Handle=pnlLeftTop.Handle then
        MainRender:=TDirectRender(Thread)
      else if TDirectRender(Thread).Handle=TPanel(Sender).Handle then
        SubRender:=TDirectRender(Thread);
      if assigned(MainRender) and assigned(SubRender) then
      begin
        MainRender.Handle:=TPanel(Sender).Handle;
        SubRender.Handle:=pnlLeftTop.Handle;
        exit;
      end;
    end;
end;

procedure TMainFM.pnlVideoResize(Sender: TObject);
var
  SingleWidth, SingleHeight: integer;
begin
  SingleWidth:=pnlVideo.Width div 3;
  SingleHeight:=pnlVideo.Height div 3;
  SetWindowPos(pnlLeftTop.Handle,0,0,0,SingleWidth*2,SingleHeight*2,SWP_NOSENDCHANGING);
  SetWindowPos(pnlRightTop.Handle,0,SingleWidth*2,0,SingleWidth,SingleHeight,SWP_NOSENDCHANGING);
  SetWindowPos(pnlRight.Handle,0,SingleWidth*2,SingleHeight,SingleWidth,SingleHeight,SWP_NOSENDCHANGING);
  SetWindowPos(pnlLeftBottom.Handle,0,0,SingleHeight*2,SingleWidth,SingleHeight,SWP_NOSENDCHANGING);
  SetWindowPos(pnlBottom.Handle,0,SingleWidth,SingleHeight*2,SingleWidth,SingleHeight,SWP_NOSENDCHANGING);
  SetWindowPos(pnlRightBottom.Handle,0,SingleWidth*2,SingleHeight*2,SingleWidth,SingleHeight,SWP_NOSENDCHANGING);
end;

end.
