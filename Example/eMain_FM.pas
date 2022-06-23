unit eMain_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  ABL.IA.ImageCutter, ABL.IA.IfMotion,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdGlobal, ABL.VS.RTSPReceiver, ABL.VS.FFMPEG, //libavcodec,
  ABL.VS.DecodedMultiplier,
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
    procedure bCreateClick(Sender: TObject);
    procedure bSendClick(Sender: TObject);
    procedure bSendTCPClick(Sender: TObject);
    procedure leRTSPLinkKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure bGoClick(Sender: TObject);
    procedure pnlVideoResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    Direct1,Direct2: TDirect;
    Timer1,Timer2: TABLTimer;
    Multiplier: TQueueMultiplier;
    TCPReader: TTCPReader;
    TCPToLog: TTCPToLog;
    RTSPReceiver: TRTSPReceiver;
    VideoDecoder: TVideoDecoder;
    Render,ResizeRender,LeftIfRender,RightIfRender: TDirectRender;
    DecodedMultiplier: TDecodedMultiplier;
    ImageResize: TImageResize;
    ImageCutter: TImageCutter;
    IfMotionLeft, IfMotionRight: TIfMotion;
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
    RightIfRender.Handle:=pnlRightBottom.Handle;
    IfMotionRight.SetOutputQueue(RightIfRender.InputQueue);
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
    DecodedMultiplier.Free;
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

procedure TMainFM.pnlVideoResize(Sender: TObject);
begin
  pnlLeftTop.Width:=pnlVideo.Width div 2;
  pnlLeftTop.Height:=pnlVideo.Height div 2;
  pnlRightTop.Width:=pnlLeftTop.Width;
  pnlRightTop.Left:=pnlLeftTop.Width;
  pnlRightTop.Height:=pnlLeftTop.Height;
  pnlLeftBottom.Top:=pnlLeftTop.Height;
  pnlLeftBottom.Height:=pnlLeftTop.Height;
  pnlLeftBottom.Width:=pnlLeftTop.Width;
  pnlRightBottom.Top:=pnlLeftTop.Height;
  pnlRightBottom.Left:=pnlLeftTop.Width;
  pnlRightBottom.Height:=pnlLeftTop.Height;
  pnlRightBottom.Width:=pnlLeftTop.Width;
end;

end.
