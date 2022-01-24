unit eMain_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdGlobal, ABL.VS.RTSPReceiver, libavcodec,
  ABL.Core.QueueMultiplier, ABL.Core.ThreadController, Vcl.ComCtrls, ABL.Render.DirectRender,
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
    procedure bCreateClick(Sender: TObject);
    procedure bSendClick(Sender: TObject);
    procedure bSendTCPClick(Sender: TObject);
    procedure leRTSPLinkKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure bGoClick(Sender: TObject);
  private
    { Private declarations }
    Direct1,Direct2: TDirect;
    Timer1,Timer2: TABLTimer;
    Multiplier: TQueueMultiplier;
    TCPReader: TTCPReader;
    TCPToLog: TTCPToLog;
    RTSPReceiver: TRTSPReceiver;
    VideoDecoder: TVideoDecoder;
    Render: TDirectRender;
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
    VideoDecoder:=TVideoDecoder.Create(ThreadController.QueueByName('Receiver_Output'),nil,AV_CODEC_ID_H264,'VideoDecoder');
  if not assigned(Render) then
  begin
    Render:=TDirectRender.Create('Render');
    Render.Handle:=pnlVideo.Handle;
    VideoDecoder.SetOutputQueue(Render.InputQueue);
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

end.
