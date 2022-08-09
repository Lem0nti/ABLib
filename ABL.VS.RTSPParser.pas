unit ABL.VS.RTSPParser;

interface

uses
  ABL.Core.DirectThread, SysUtils, ABL.IO.IOTypes, {$IFDEF UNIX}sockets{$ELSE}WinSock{$ENDIF}, ABL.Core.BaseQueue,
  ABL.Core.Debug, SyncObjs;

type
  /// <summary>
  /// Заголовок RTSP-пакета.
  /// </summary>
  /// <param name="Magic: byte">
  /// Подпись пакета - байт равный 36 (х24).
  /// </param>
  /// <param name="Channel: byte">
  /// Канал камеры.
  /// </param>
  /// <param name="Length: word">
  /// Количеоство байт в пакете.
  /// </param>
  TRTSPHeader=record
    Magic: byte;  //всегда должен быть равен х24
    Channel: byte;
    Length: word;
  end;

  /// <summary>
  /// Поток для распарсивания пакетов в кадры.
  /// </summary>

  { TRTSPParser }

  TRTSPParser=class(TDirectThread)
  private
    CurFrame: TBytes;
    InputBuffer: TBytes;
    OldPacketType: byte;
    BadFrameCount: Word;
    NTime,FLastFrameTime: int64;
    function GetLastFrameTime: int64;
  protected
    {$IFDEF FPC}
    procedure ClearData(AData: Pointer); override;
    {$ENDIF}
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    SPSPPSFrame_7_8: TBytes;
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    procedure DropNTime;
    property LastFrameTime: int64 read GetLastFrameTime;
  end;

const
  SPayloadType: array [0..34] of String = ('PCMU', 'CELP', 'G.721', 'GSM', 'G.723', 'DVI4 (5)', 'DVI4 (6)', 'LPC', 'PCMA', 'G.722',
                                           'L16 (10)', 'L16 (11)', 'QCELP', 'CN', 'MPA', 'G728', 'DVI4 (16)', 'DVI4 (17)', 'G729',
                                           '', '', '', '', '', '', 'CELB', 'JPEG', '', 'nv', '', '','H261', 'MPV', 'MP2T', 'H263');

implementation

{ TRTPParser }

constructor TRTSPParser.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  OldPacketType:=0;
  NTime:=0;
end;

procedure TRTSPParser.DoExecute(var AInputData: Pointer;
  var AResultData: Pointer);
var
  ReadedData,ResultData: PDataFrame;
  DataPassed,OldDataPassed,EHLOffset: Cardinal;
  RTSPHeader: TRTSPHeader;
  PayloadType,Byte_1,Byte_0,x,CSRCCount,NRI,Byte_PayLoad,PacketType,FrameType: byte;
  EndMarker,AssertMarker: boolean;
  EHL,Payload,Sequence,DataSize: word;
  q: integer;
  AStringForLog: string;
  tmpLTimeStamp: TTimeStamp;
begin
  DataPassed:=0;
  try
    ReadedData:=PDataFrame(AInputData);
    try
      SetLength(InputBuffer,length(InputBuffer)+ReadedData^.Size);
      Move(ReadedData^.Data^,InputBuffer[length(InputBuffer)-ReadedData^.Size],ReadedData^.Size);
    finally
      FreeMem(ReadedData^.Data);
    end;
    while DataPassed<length(InputBuffer) do
    begin
      if Terminated then
        exit;
      Move(InputBuffer[DataPassed],RTSPHeader,4);
      if (RTSPHeader.Magic=36) { $24 } and (RTSPHeader.Channel in [0..4]) then
      begin
        RTSPHeader.Length:=htons(RTSPHeader.Length);
        if DataPassed+4+RTSPHeader.Length>length(InputBuffer) then  //это значит что данные для этого кадра будут позже
          break
        else
        begin
          inc(DataPassed,4);
          Byte_0:=InputBuffer[DataPassed];
          Byte_1:=InputBuffer[DataPassed+1];
          PayloadType:=Byte_1 AND $7F;  //01111111 - 7 бит
          if PayloadType in [96,99,105] then
          begin
            EndMarker:=(Byte_1 AND $80)=128;  //10000000 - первый бит
            //расширенный заголовок
            if (Byte_0 AND $10)=16 then         //00010000 - бит номер 3
              x:=1
            else
              x:=0;
            //количество CSRC
            CSRCCount:=Byte_0 AND $F;  //00001111 - 4 последних бита
            if x=1 then
            begin
              //EHL
              EHLOffset:=12+CSRCCount*4+2; //96+CSRCCount*32+16 в битах
              move(InputBuffer[DataPassed+EHLOffset],EHL,2);
              EHL:=htons(EHL);  //прееворот байтов
            end
            else
              EHL:=0;
            move(InputBuffer[DataPassed+2],Sequence,2);
            Sequence:=htons(Sequence);
            //адрес равен 12+CSRCCount*4+x*4+x*EHL
            Payload:=12+(CSRCCount+x)*4+x*EHL;
            if DataPassed+Payload<length(InputBuffer) then
            begin
              Byte_PayLoad:=InputBuffer[DataPassed+Payload];
              AssertMarker:=(Byte_PayLoad AND $80)=128;  //10000000 - первый бит
              if not AssertMarker then
              begin
                //тип NAL
                NRI:=Byte_PayLoad AND $60;  //01100000 - 2 и 3 биты
                //RFC 6184 - тут написано, что если NRI рано 0, то пакет можно игнорировать
                //обычно это фрейм 6
                if NRI>0 then
                begin
                  PacketType:=Byte_PayLoad AND $1F;  //00011111 - 5 последних бит
                  if PacketType=28 then
                  begin
                    inc(Payload);
                    FrameType:=InputBuffer[DataPassed+Payload] AND $1F;  //00011111 - 5 последних бит
                  end
                  else
                    FrameType:=PacketType;
                  if FrameType in [1,5,7,8] then  //работать только с фреймами 1, 5, 7, 8
                  begin
                    DataSize:=RTSPHeader.Length-Payload;
                    if NTime=0 then
                    begin
                      tmpLTimeStamp := DateTimeToTimeStamp(now);
                      NTime:=tmpLTimeStamp.Date*Int64(MSecsPerDay)+tmpLTimeStamp.Time-UnixTimeStart;
                    end;
                      //NTime:=ReadedData^.Time;
                    if (OldPacketType<>28) or (PacketType<>28) then  //если PacketType=28, то только для первого такого пакета
                    begin
                      SetLength(CurFrame,length(CurFrame)+3);
                      CurFrame[length(CurFrame)-1]:=1;
                    end;
                    //если OldPacketType не 28 и PacketType 28, то тип кадра вписывать как $60+FrameType и сдвигать точку копирования на байт вперёд
                    if PacketType=28 then
                    begin
                      if OldPacketType<>28 then
                      begin
                        SetLength(CurFrame,length(CurFrame)+1);
                        CurFrame[length(CurFrame)-1]:=96+FrameType;
                      end;
                      inc(Payload);
                      dec(DataSize)
                    end;
                    SetLength(CurFrame,length(CurFrame)+DataSize);
                    OldPacketType:=PacketType;
                    if DataSize>0 then
                      move(InputBuffer[DataPassed+Payload],CurFrame[length(CurFrame)-DataSize],DataSize);
                    if EndMarker and (not (FrameType in [7,8])) then //7 и 8 кадр не отправлять самостоятельно
                    begin
                      OldPacketType:=FrameType;
                      //отправить дальше
                      if assigned(FOutputQueue) then
                      begin
                        New(ResultData);
                        ResultData^.Size:=length(CurFrame);
                        ResultData^.Reserved:=0;
                        //если фрейм 5, и без 7 и 8, то послать их
                        if CurFrame[3]=101 then  //$65
                        begin
                          if length(SPSPPSFrame_7_8)>0 then
                          begin
                            ResultData^.Size:=ResultData^.Size+length(SPSPPSFrame_7_8);
                            GetMem(ResultData^.Data,ResultData^.Size);
                            Move(SPSPPSFrame_7_8[0],ResultData^.Data^,length(SPSPPSFrame_7_8));
                            Move(CurFrame[0],PByte(NativeUInt(ResultData^.Data)+NativeUInt(length(SPSPPSFrame_7_8)))^,length(CurFrame));
                          end
                          else
                          begin
                            SendErrorMsg('TRTSPParser('+FName+').DoExecute 200: нет SPS и PPS кадров');
                            SubThread.Terminate;
                            Dispose(ResultData);
                            exit;
                          end;
                        end
                        else
                        begin
                          //скопировать
                          GetMem(ResultData^.Data,ResultData^.Size);
                          Move(CurFrame[0],ResultData^.Data^,ResultData^.Size);
                        end;
                        if Terminated then
                          exit;
                        ResultData^.Time:=NTime;
                        Lock;
                        FLastFrameTime:=NTime;
                        Unlock;
                        if assigned(FOutputQueue) then
                          FOutputQueue.Push(ResultData)  // так а не через аутпутдата, потому что на один пакет может быть несколько кадров
                        else //нет ничего
                          SubThread.Terminate;
                      end;
                      SetLength(CurFrame,0);
                      NTime:=0;
                    end;
                  end
                  else if FrameType<>24 then  //можно пропускать 24 (возможно и другие)
                  begin
{      24       STAP-A    Single-time aggregation packet
      25       STAP-B    Single-time aggregation packet
      26       MTAP16    Multi-time aggregation packet
      27       MTAP24    Multi-time aggregation packet }
                    //возможно это временно, просто очистить текущий буффер кадра
                    SetLength(CurFrame,0);
                    inc(BadFrameCount);
                    if BadFrameCount mod 256 = 0 then
                    begin
                      SendErrorMsg('TRTSPParser('+FName+').DoExecute 238: неподдерживаемый формат, FrameType='+IntToStr(FrameType)+', PacketType='+IntToStr(PacketType));
                      if BadFrameCount>=32768 then
                      begin
                        Stop;
                        if assigned(Parent) then
                          Parent.ChildCB(self);
                        exit;
                      end;
                    end;
                  end;
                end;
              end;
            end
            else
              //неправильный PayLoad
              SendErrorMsg('TRTSPParser.DoExecute 247: неправильный PayLoad='+IntToStr(PayLoad)+', CSRCCount='+IntToStr(CSRCCount)+', x='+IntToStr(x)+', EHL='+IntToStr(EHL));
          end
          else if not (PayloadType in [72..76]) then  //72-76 можно игнорировать
          begin
            inc(BadFrameCount);
            if BadFrameCount>=192 then
            begin
              if PayloadType<length(SPayloadType) then
                AStringForLog:=SPayloadType[PayloadType]
              else
                AStringForLog:='';
              if AStringForLog<>'' then
                AStringForLog:=' ('+AStringForLog+')';
              SendErrorMsg('TRTSPParser('+FName+').DoExecute 260: неподдерживаемый формат, PayloadType='+IntToStr(PayloadType)+AStringForLog);
              SubThread.Terminate;
              BadFrameCount:=0;
              //всё что в буффере - в лог
              AStringForLog:='';
              for q:=0 to length(InputBuffer)-1 do
                if InputBuffer[q]>0 then
                  AStringForLog:=AStringForLog+Char(AnsiChar(InputBuffer[q]))
                else
                  AStringForLog:=AStringForLog+' ';
              SendTCPMsg(AStringForLog+#13#10'[270]');
            end;
          end;
          DataPassed:=DataPassed+RTSPHeader.Length;
        end;
      end
      else        //в сокете мусор или ответ на пинг
      begin
        OldDataPassed:=DataPassed;
        inc(DataPassed);
        while DataPassed<length(InputBuffer) do
          if InputBuffer[DataPassed]=36 { $24 } then
            break
          else
            inc(DataPassed);
        AStringForLog:='';
        //всё что обрезано, запихнуть в txt
        for q:=OldDataPassed to DataPassed-1 do
          if InputBuffer[q]>0 then
            AStringForLog:=AStringForLog+Char(AnsiChar(InputBuffer[q]))
          else
            AStringForLog:=AStringForLog+' ';
        SendTCPMsg(AStringForLog+#13#10'[292]');
      end;
    end;
  except on e: Exception do
    SendErrorMsg('TRTSPParser.DoExecute 296 length(InputBuffer)='+IntToStr(length(InputBuffer))+', DataPassed='+IntToStr(DataPassed)+': '+e.ClassName+' - '+e.Message);
  end;
  try
    //отрезаем лишний буффер
    {$IFDEF UNIX}
    q:=length(InputBuffer)-DataPassed;
    Move(InputBuffer[DataPassed],InputBuffer[0],q);
    SetLength(InputBuffer,q);
    {$ELSE}
    delete(InputBuffer,0,DataPassed);
    {$ENDIF}
  except on e: Exception do
    SendErrorMsg('TRTPParser.DoExecute 308, DataPassed='+IntToStr(DataPassed)+': '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TRTSPParser.DropNTime;
begin
  FLock.Enter;
  try
    NTime:=0;
  finally
    FLock.Leave;
  end;
end;

function TRTSPParser.GetLastFrameTime: int64;
begin
  FLock.Enter;
  try
    result:=FLastFrameTime;
  finally
    FLock.Leave;
  end;
end;

{$IFDEF FPC}
procedure TRTSPParser.ClearData(AData: Pointer);
var
  DataFrame: PDataFrame;
begin
  DataFrame:=PDataFrame(AData);
  FreeMem(DataFrame^.Data);
  Dispose(DataFrame);
end;
{$ENDIF}

end.
