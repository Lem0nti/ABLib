﻿unit ABL.VS.VideoDecoder;

interface

uses
  ABL.Core.DirectThread, ABL.VS.FFMPEG,
  ABL.Core.BaseQueue, ABL.IO.IOTypes, SyncObjs,
  ABL.VS.VSTypes, ABL.Core.Debug, SysUtils;

type

  { TVideoDecoder }

  TVideoDecoder=class(TDirectThread)
  private
    BadDecodeCounter: byte;
    pkt: PAVPacket;
    frame,m_OutPicture: PAVFrame;
    codec: PAVCodec;
    VideoContext: PAVCodecContext;
    sws_ctx: PSwsContext;
    PrevWidth: integer;
    FCodec: TAVCodecID;
    LastFrameTime: int64;
  protected
    {$IFDEF FPC}
    procedure ClearData(AData: Pointer); override;
    {$ENDIF}
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
    procedure InitDecoder;
    procedure CloseDecoder;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; ACodec: TAVCodecID; AName: string = ''); reintroduce;
    destructor Destroy; override;
    procedure PushLastFrame;
  end;

implementation

{ TVideoDecoder }

procedure TVideoDecoder.CloseDecoder;
begin
  if assigned(m_OutPicture) then
    av_frame_free(@m_OutPicture);
  m_OutPicture := nil;
  FLock.Enter;
  av_frame_free(@frame);
  FLock.Leave;
  avcodec_close(VideoContext);
  avcodec_free_context(@VideoContext);
  av_packet_free(@pkt);
end;

constructor TVideoDecoder.Create(AInputQueue, AOutputQueue: TBaseQueue; ACodec: TAVCodecID; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  BadDecodeCounter:=0;
  PrevWidth:=0;
  FCodec:=ACodec;
  InitDecoder;
  Start;
end;

{$IFDEF FPC}
procedure TVideoDecoder.ClearData(AData: Pointer);
var
  DataFrame: PDataFrame;
begin
  DataFrame:=PDataFrame(AData);
  Dispose(DataFrame);
end;
{$ENDIF}

destructor TVideoDecoder.Destroy;
begin
  Stop;
  CloseDecoder;
  inherited;
end;

procedure TVideoDecoder.DoExecute(var AInputData: Pointer;
  var AResultData: Pointer);
var
  CFrame: PDataFrame;
  got_picture,DSize: integer;
  DecodedFrame: PDecodedFrame;
begin
  try
    CFrame:=PDataFrame(AInputData);
    try
      if CFrame^.Size=0 then
      begin
        SendDebugMsg('TVideoDecoder.DoExecute 93: CFrame^.Size=0');
        exit;
      end;
      if Terminated then
        exit;
      pkt^.size:=CFrame^.Size;
      pkt^.data:=CFrame^.Data;
      FLock.Enter;
      try
        if assigned(frame) then
        begin
          avcodec_decode_video2(VideoContext, frame, @got_picture, pkt);
          if got_picture=1 then
          begin
            if CFrame.Reserved=0 then
            begin
              if (VideoContext^.width <> PrevWidth) and assigned(m_OutPicture) then
              begin
                av_frame_free(@m_OutPicture);
                m_OutPicture := nil;
              end;
              PrevWidth:=VideoContext^.width;
              if not assigned(m_OutPicture) then
              begin
                m_OutPicture := av_frame_alloc;
                avpicture_alloc(PAVPicture(m_OutPicture), AV_PIX_FMT_BGR24, VideoContext^.width, VideoContext^.height );
                sws_ctx:=sws_getContext(VideoContext^.width,VideoContext^.height,VideoContext^.pix_fmt,VideoContext^.width,VideoContext^.height,
                    AV_PIX_FMT_BGR24,SWS_BICUBIC,nil,nil,nil);
              end;
              sws_scale(sws_ctx, @frame^.data, @frame^.linesize, 0, VideoContext^.height, @m_OutPicture^.data, @m_OutPicture^.linesize);
              if Terminated then
                exit;
              if assigned(FOutputQueue) then
              begin
                LastFrameTime:=CFrame^.Time;
                new(DecodedFrame);
                DecodedFrame^.Time:=CFrame^.Time;
                DecodedFrame^.Width:=VideoContext^.width;
                DecodedFrame^.Height:=VideoContext^.height;
                DecodedFrame^.Left:=0;
                DecodedFrame^.Top:=0;
                DecodedFrame^.ImageType:=itBGR;
                DSize:=DecodedFrame^.Width*DecodedFrame^.Height*3;
                GetMem(DecodedFrame^.Data,DSize);
                Move(m_OutPicture^.data[0]^,DecodedFrame^.Data^,DSize);
                if Terminated then
                  exit;
                FOutputQueue.Push(DecodedFrame);
              end;
            end;
          end
          else
          begin
            inc(BadDecodeCounter);
            if BadDecodeCounter>=192 then
            begin
              SendErrorMsg('TVideoDecoder('+FName+').DoExecute 134, ошибочное декодирование: InSize='+IntToStr(CFrame^.Size)+':'+IntToStr(VideoContext^.
                  Width)+'x'+IntToStr(VideoContext^.Height));
              CloseDecoder;
              InitDecoder;
              BadDecodeCounter:=0
            end;
          end;
        end;
      finally
        FLock.Leave;
      end;
    finally
      if CFrame^.Size>0 then
        FreeMem(CFrame^.Data);
    end;
  except on e: Exception do
    if not FTerminated then
      SendErrorMsg('TVideoDecoder.DoExecute 152: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TVideoDecoder.InitDecoder;
begin
  pkt := av_packet_alloc;
  m_OutPicture := nil;
  //создали декодер
  codec := avcodec_find_decoder(FCodec);
  VideoContext := avcodec_alloc_context3(codec);
  avcodec_open2(VideoContext, codec, nil);
  //фрейм для выходных данных
  frame := av_frame_alloc;
  pkt^.flags:=0;
end;

procedure TVideoDecoder.PushLastFrame;
var
  DecodedFrame: PDecodedFrame;
  DSize: integer;
begin
  if assigned(m_OutPicture) then
  begin
    new(DecodedFrame);
    DecodedFrame^.Time:=LastFrameTime;
    DecodedFrame^.Width:=VideoContext^.width;
    DecodedFrame^.Height:=VideoContext^.height;
    DSize:=DecodedFrame^.Width*DecodedFrame^.Height*3;
    GetMem(DecodedFrame^.Data,DSize);
    Move(m_OutPicture^.data[0]^,DecodedFrame^.Data^,DSize);
    FOutputQueue.Push(DecodedFrame);
  end;
end;

end.
