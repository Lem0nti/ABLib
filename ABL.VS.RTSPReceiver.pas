unit ABL.VS.RTSPReceiver;

interface

uses
  ABL.Core.BaseObject, Classes, SyncObjs, ABL.IO.TCPReader, ABL.VS.RTSPParser, ABL.Core.ThreadQueue,
  {$IFDEF UNIX}sockets{$ELSE}WinSock{$ENDIF}, ABL.VS.URI, SysUtils, ABL.Core.Debug, ABL.IO.IOTypes,
  {$IFDEF FPC}md5, base64{$ELSE}IdHashMessageDigest, NetEncoding{$ENDIF}, ABL.Core.BaseQueue;

type
  TRTSPReceiver=class;

    /// <summary>
    /// Класс для логического "пинга" видеокамер.
    /// Многие видеокамеры требуют периодического сигнала от потребителей видео, чтобы продолжать трансляцию.
    /// </summary>
  TLogicPing=class(TThread)
  private
    FLock: TCriticalSection;
    FParent: TRTSPReceiver;
    FTimeOut: integer;
    FWaitForStop: TEvent;
  protected
    procedure Execute; override;
  public
    /// <summary>
    /// Конструктор.
    /// </summary>
    /// <param name="AParent: TRTSPReceiver">
    /// Приёмник, от имени которого должен посылаться сигнал.
    /// </param>
    /// <param name="ATimeOut: integer">
    /// Периодичность в миллисекундах, с которой необходимо отправлять данные.
    /// </param>
    Constructor Create(AParent: TRTSPReceiver; ATimeOut: integer); reintroduce;
    Destructor Destroy; override;
    procedure Stop;
  end;

  TRTSPReceiver=class(TBaseObject)
  private
    FCSeq,PingInterval: integer;
    LogicPing: TLogicPing;
    TCPReader: TTCPReader;
    RTSPParser: TRTSPParser;
    ThreadQueue: TThreadQueue;
    CurSession,TrackLink: AnsiString;
    FConnectionString,realm,nonce,FLastError: string;
    FSocket: TSocket;
    procedure Connect;
    function CSeq: AnsiString;
    function GenerateAuthString(AUsername, APassword, ARealm, AMethod, AUri, ANonce: string): string;
    function SendDescribe: boolean;
    procedure SendPlay;
    function SendReceive(AText: AnsiString; Receive: boolean = true): string;
    function SendReceiveMethod(AMethod, AURL, AHeadersText: AnsiString): string;
    function SendSetup: boolean;
    function GetActive: boolean;
    function GetConnectionString: string;
    procedure SetActive(const Value: boolean);
    procedure SetConnectionString(const Value: string);
    procedure SetThisLastError(ALastError: string);
  public
    Link: TURI;
    constructor Create(AOutputQueue: TThreadQueue; AName: string = ''; AConnectionString: string = ''); reintroduce;
    destructor Destroy; override;
    function LastError: string;
    function LastFrameTime: int64;
    function ReadSize: Cardinal;
    function SendSetParameter: string;
    procedure SendTeardown;
    procedure SetOutputQueue(Queue: TBaseQueue);
    property Active: boolean read GetActive write SetActive;
    property ConnectionString: string read GetConnectionString write SetConnectionString;
  end;

{$IFDEF MSWINDOWS}
var
  WSAReady: boolean = false;
  WSAData: TWSAData;
{$ENDIF}

const
  USER_AGENT = 'ABL.TRTSPReceiver 1.0.8';
  SCommand: array [0..4] of String = ('DESCRIBE', 'PLAY', 'SET_PARAMETER', 'SETUP', 'TEARDOWN');

implementation

{$IFDEF MSWINDOWS}
function CheckWSAReady: boolean;
begin
  WSAReady:=WSAReady or (WSAStartup($101,WSAData)=0);
  if not WSAReady then
    SendErrorMsg('ABL.VS.RTSPReceiver.CheckWSAReady 88: '+SysErrorMessage(WSAGetLastError));
  result:=WSAReady;
end;
{$ENDIF}

{ TLogicPing }

constructor TLogicPing.Create(AParent: TRTSPReceiver; ATimeOut: integer);
begin
  inherited Create(false);
  FParent:=AParent;
  FTimeOut:=ATimeOut;
  FWaitForStop:=TEvent.Create(nil,True,False,'');
  FLock:=TCriticalSection.Create;
end;

destructor TLogicPing.Destroy;
begin
  FreeAndNil(FWaitForStop);
  FLock.Free;
  inherited;
end;

procedure TLogicPing.Execute;
var
  aStopped: TWaitResult;
  tmpResult: integer;
  StrNum,tmpHost: string;
begin
  FreeOnTerminate:=true;
  try
    StrNum:='125';
    tmpHost:=FParent.Link.Host;
    if FTimeOut<=10000 then
    begin
      SendErrorMsg('TLogicPing.Execute 128: слишком маленький таймаут ('+tmpHost+') - '+IntToStr(FTimeOut div 1000));
      FTimeOut:=60000;
    end;
      while not Terminated do
        try
          aStopped:=FWaitForStop.WaitFor(FTimeOut);
          if (aStopped=wrTimeOut) and assigned(FParent) then
          begin
            StrNum:='136';
            try
              tmpResult:=StrToIntDef(FParent.SendSetParameter,0);
            except on e: Exception do
              begin
                SendDebugMsg('TLogicPing.Execute 142: unassigend FParent for '+tmpHost+', stop ping');
                FParent:=nil;
                break;
              end;
            end;
            if tmpResult<0 then
            begin
              SendErrorMsg('TLogicPing.Execute 148: Host='+tmpHost+', SendSetParameter='+IntToStr(-tmpResult)+', Stop');
              break;
            end;
          end
          else
            break;
        except on e: Exception do
          SendErrorMsg('TLogicPing.Execute 155, StrNum='+StrNum+', Terminated='+BoolToStr(Terminated,true)+' ('+tmpHost+'): '+e.ClassName+' - '+e.Message);
        end;
  finally
    Terminate;
  end;
  if assigned(FParent) then
    FParent.LogicPing:=nil;
end;

procedure TLogicPing.Stop;
begin
  FLock.Enter;
  try
    FWaitForStop.SetEvent;
  finally
    FLock.Leave;
  end;
end;

{ TRTSPReceiver }

procedure TRTSPReceiver.Connect;
var
  w: String;
  sl: TStringList;
  q: integer;
  Addr: sockaddr_in;
  {$IFDEF UNIX}
  e: longint;
  {$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if not CheckWSAReady then
    exit;
  {$ENDIF}
  SendDebugMsg('TRTSPReceiver.Connect 162: '+Link.GetFullURI);
  FSocket:=0;
  RTSPParser.DropNTime;
  {$IFDEF UNIX}
  FSocket:=fpSocket(AF_INET,SOCK_STREAM,IPPROTO_IP);
  {$ELSE}
  FSocket:=Socket(AF_INET,SOCK_STREAM,IPPROTO_IP);
  {$ENDIF}
  if FSocket<>INVALID_SOCKET then
  begin
    Addr.sin_family:=AF_INET; // тип то же что и у сокета
    Addr.sin_port:=htons(StrToIntDef(Link.Port,554)); // порт, htons обязательно !
    {$IFDEF UNIX}
    Addr.sin_addr:=StrToNetAddr(AnsiString(Link.Host));
    e:=fpconnect(FSocket,@Addr,SizeOf(Addr));
    if e=SOCKET_ERROR then
    {$ELSE}                                                                 
    Addr.sin_addr.S_addr:=inet_addr(PAnsiChar(AnsiString(Link.Host))); // ip
    if WinSock.connect(FSocket,Addr,SizeOf(Addr))=SOCKET_ERROR then
    {$ENDIF}
      SendErrorMsg('TRTSPReceiver.Connect 201 ('+Link.GetFullURI+'): '+{$IFDEF UNIX}'connect error '+IntToStr(e){$ELSE}SysErrorMessage(WSAGetLastError){$ENDIF})
    else
    begin
      FCSeq := 1;
      w:=SendReceiveMethod('OPTIONS',AnsiString(Link.GetFullURI),'');
      if w='' then
        SendErrorMsg('TRTSPReceiver.Connect 207: empty OPTIONS request')
      else
      begin
        sl:=TStringList.Create;
        try
          sl.Text:=StringReplace(w,': ','=',[rfReplaceAll]);
          w:=trim(sl.Values['Public']);
          if w='' then
            SendErrorMsg('TRTSPReceiver.Connect 215: пустой список команд камеры '#13#10+sl.Text)
          else
          begin
            sl.Text:=StringReplace(StringReplace(w,', ',#13#10,[rfReplaceAll]),',',#13#10,[rfReplaceAll]);
            //если нет какой-нибудь из нужных команд - сообщить об этом в лог
            for q:=0 to length(SCommand)-1 do
              if sl.IndexOf(SCommand[q])=-1 then
                SendErrorMsg('TRTSPReceiver.Connect 222: '+Link.GetFullURI+' не поддерживает команду '+SCommand[q]);
          end;
        finally
          FreeAndNil(sl);
        end;
        if SendDescribe then
          if SendSetup then
            SendPlay
          else
            SendErrorMsg('TRTSPReceiver.Connect 231: SendSetup=false')
        else
          SendErrorMsg('TRTSPReceiver.Connect 233: SendDescribe=false');
      end;
    end;
  end
  else
    SendErrorMsg('TRTSPReceiver.Connect 238: '+
        {$IFDEF UNIX}'socket error '+IntToStr(FSocket){$ELSE}SysErrorMessage(WSAGetLastError){$ENDIF});
end;

constructor TRTSPReceiver.Create(AOutputQueue: TThreadQueue; AName, AConnectionString: string);
begin
  inherited Create(AName);
  ThreadQueue:=TThreadQueue.Create(ClassName+'_'+AName+'_Reader2Parser_'+IntToStr(FID));
  TCPReader:=TTCPReader.Create(ThreadQueue,ClassName+'_'+AName+'_Reader_'+IntToStr(FID));
  TCPReader.Parent:=Self;
  RTSPParser:=TRTSPParser.Create(ThreadQueue,AOutputQueue,ClassName+'_'+AName+'_Parser_'+IntToStr(FID));
  RTSPParser.Parent:=Self;
  RTSPParser.Active:=true;
  Link:=TURI.Create;
  SetConnectionString(AConnectionString);
  if FConnectionString<>'' then
    SetActive(true);
end;

function TRTSPReceiver.CSeq: AnsiString;
begin
  result:=AnsiString(IntToStr(FCSeq));
  inc(FCSeq);
end;

destructor TRTSPReceiver.Destroy;
begin
  closesocket(FSocket);
  FreeAndNil(TCPReader);
  FreeAndNil(RTSPParser);
  FreeAndNil(ThreadQueue);
  Link.Free;
  inherited;
end;

function TRTSPReceiver.GenerateAuthString(AUsername, APassword, ARealm, AMethod, AUri, ANonce: string): string;
var
  m1,m2,response: string;

  function ResultString(const S: String): String;
  begin
    Result := '';
    {$IFDEF FPC}
    Result:=MD5Print(MD5String(s));
    {$ELSE}
    with TIdHashMessageDigest5.Create do
      try
        Result:=AnsiLowerCase(HashStringAsHex(s));
      finally
        Free;
      end;
    {$ENDIF}
  end;

begin
  result:='';
  m1:=ResultString(AUsername+':'+ARealm+':'+APassword);
  m2:=ResultString(AMethod+':'+AUri);
  response:=ResultString(m1+':'+ANonce+':'+m2);
  result:='Digest username="'+AUsername+'", realm="'+ARealm+'", nonce="'+ANonce+'", uri="'+AUri+'", response="'+response+'"';
end;

function TRTSPReceiver.GetActive: boolean;
begin
  result:=FSocket>0;
end;

function TRTSPReceiver.GetConnectionString: string;
begin
  Lock;
  try
    result:=FConnectionString;
  finally
    Unlock;
  end;
end;

function TRTSPReceiver.LastError: string;
begin
  FLock.Enter;
  try
    result:=FLastError;
    FLastError:='';
  finally
    FLock.Leave;
  end;
end;

function TRTSPReceiver.LastFrameTime: int64;
begin
  result:=RTSPParser.LastFrameTime;
end;

function TRTSPReceiver.ReadSize: Cardinal;
begin
  result:=TCPReader.ReadSize;
end;

function TRTSPReceiver.SendDescribe: boolean;
var
  w,q,vURL,FURI1,FURI2,ReceivedText: string;
  sl,sl1: TStringList;
  I,e,r: integer;
  NType: byte;  //0 - не было получения, 1 - управление, 2 - видео, 3 - аудио
  SPSFrame_7,PPSFrame_8: TBytes;
  {$IFDEF FPC}
  Base64MidStream, Base64ResultStream: TStringStream;
  Base64DecodeStream: TBase64DecodingStream;
  {$ENDIF}
begin
  CurSession:='';
  TrackLink:='';
  result:=false;
  try
    sl:=TStringList.Create;
    try
      ReceivedText:=SendReceiveMethod('DESCRIBE',AnsiString(Link.GetFullURI),'');
      sl.Text:=StringReplace(ReceivedText,': ','=',[rfReplaceAll]);
      //ищем ссылки
      NType:=0;
      vURL:='';
      //может быть или не быть слэш в изначальной ссылке, проверять это по результатам ответа
      FURI1:=Link.GetFullURI;
      FURI2:=FURI1;
      r:=pos('?',FURI2);
      if r>0 then
      begin
        if FURI2[r-1]='/' then
          Delete(FURI2,r-1,1)
        else
          Insert('/',FURI2,r);
      end
      else
      begin
        if FURI2[length(FURI2)]='/' then
          delete(FURI2,length(FURI2),1)
        else
          FURI2:=FURI2+'/';
      end;
      for I := 0 to sl.Count-1 do
      begin
        q:=sl[I];
        if length(q)>7 then  //интересующие нас маркеры больше 7 символов
        begin
          w:=copy(q,1,7);
          //собираем ссылки
          if w='a=type:' then
            NType:=1
          else if w='a=fmtp:' then  //тут может быть PPS и SPS - a=fmtp:96 packetization-mode=1;profile-level-id=64002a;sprop-parameter-sets=Z2QAKqzZQHgCJ+XARAAAAwAEAAADAeI8YMZY,aOvjyyLA;
          begin
            sl1:=TStringList.Create;
            try
              sl1.Text:=StringReplace(StringReplace(q,'; ',#13#10,[rfReplaceAll]),';',#13#10,[rfReplaceAll]);
              q:=trim(sl1.Values['sprop-parameter-sets']);
            finally
              FreeAndNil(sl1);
            end;
            if q<>'' then
            begin
              //параметры камеры
              //должна быть запятая, она разделяет PPS и SPS
              e:=pos(',',q);
              if e>0 then
              begin
                {$IFDEF FPC}
                Base64MidStream:=TStringStream.Create(copy(q,1,e-1));
                try
                  Base64ResultStream:=TStringStream.Create('');
                  try
                    Base64DecodeStream:=TBase64DecodingStream.Create(Base64MidStream);
                    try
                      Base64ResultStream.CopyFrom(Base64DecodeStream,Base64DecodeStream.Size);
                      Base64ResultStream.Read(SPSFrame_7,Base64ResultStream.Size);
                    finally
                      Base64DecodeStream.Free;
                    end;
                  finally
                    Base64ResultStream.Free;
                  end;
                finally
                  Base64MidStream.Free;
                end;          
                Base64MidStream:=TStringStream.Create(copy(q,e+1,512));
                try
                  Base64ResultStream:=TStringStream.Create('');
                  try
                    Base64DecodeStream:=TBase64DecodingStream.Create(Base64MidStream);
                    try
                      Base64ResultStream.CopyFrom(Base64DecodeStream,Base64DecodeStream.Size);
                      Base64ResultStream.Read(PPSFrame_8,Base64ResultStream.Size);
                    finally
                      Base64DecodeStream.Free;
                    end;
                  finally
                    Base64ResultStream.Free;
                  end;
                finally
                  Base64MidStream.Free;
                end;
                {$ELSE}
                SPSFrame_7:=TNetEncoding.Base64.DecodeStringToBytes(copy(q,1,e-1));
                PPSFrame_8:=TNetEncoding.Base64.DecodeStringToBytes(copy(q,e+1,512));
                {$ENDIF}
                SetLength(RTSPParser.SPSPPSFrame_7_8,length(SPSFrame_7)+length(PPSFrame_8)+6);
                RTSPParser.SPSPPSFrame_7_8[0]:=0;
                RTSPParser.SPSPPSFrame_7_8[1]:=0;
                RTSPParser.SPSPPSFrame_7_8[2]:=1;
                move(SPSFrame_7[0],RTSPParser.SPSPPSFrame_7_8[3],length(SPSFrame_7));
                RTSPParser.SPSPPSFrame_7_8[length(SPSFrame_7)+3]:=0;
                RTSPParser.SPSPPSFrame_7_8[length(SPSFrame_7)+4]:=0;
                RTSPParser.SPSPPSFrame_7_8[length(SPSFrame_7)+5]:=1;
                move(PPSFrame_8[0],RTSPParser.SPSPPSFrame_7_8[length(SPSFrame_7)+6],length(PPSFrame_8));
              end
              else
                SendErrorMsg('TRTSPReceiver.SendDescribe 421, sprop-parameter-sets не содержит разделителя');
            end;
          end
          else if w='m=video' then  //здесь же указывается тип и PayLoad Type - m=video 0 RTP/AVP 96
            NType:=2
          else if w='m=audio' then  //когда-нибудь будем работать и со звуком
            NType:=3
          else if w='a=contr' then
          begin
            vURL:=copy(q,11,1024);
            if (vURL='*') or (vURL=FURI1) or (vURL=FURI2) then
              vURL:=''
            else if pos('tsp://',vURL)=0 then
              vURL:=Link.GetFullURI+'/'+vURL;
          end;
          if (NType>0)and(vURL<>'')and(TrackLink='') then
          begin
            if NType=2 then
              TrackLink:=AnsiString(vURL);
            NType:=0;
            vURL:='';
          end;
        end;
      end;
      result:=TrackLink<>'';
      if not result then
      begin
        SendErrorMsg('TRTSPReceiver.SendDescribe ('+Link.Host+') 448: нет ссылок для трансляции'#13#10+Link.GetFullURI+#13#10+ReceivedText);
      end;
    finally
      FreeAndNil(sl);
    end;
  except on e: Exception do
    SendErrorMsg('TRTSPReceiver.SendDescribe ('+Link.Host+') 454: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TRTSPReceiver.SendPlay;
var
  w: string;
  StrNum: string;
begin
  if CurSession='' then
    SendErrorMsg('TRTSPReceiver.SendPlay ('+Link.Host+') 463: нет сессии')
  else
    try
      StrNum:='498';
      w:=SendReceiveMethod('PLAY',AnsiString(Link.GetFullURI),'Session: '+CurSession);
      if pos('200 OK',w)>0 then
      begin
        SendDebugMsg('TRTSPReceiver.SendPlay ('+Link.GetFullURI+') 502: 200 OK');
        TCPReader.SetAcceptedSocket(FSocket);
        StrNum:='504';
        if assigned(LogicPing) then
        begin
          try
            LogicPing.Stop;
          except on e: Exception do
            SendErrorMsg('TRTSPReceiver.SendPlay ('+Link.Host+') 512, LogicPing.Stop: '+e.ClassName+' - '+e.Message);
          end;
        end;
        StrNum:='513';
        LogicPing:=TLogicPing.Create(self,PingInterval);
      end
      else
        SendErrorMsg('TRTSPReceiver.SendPlay ('+Link.Host+') 519:'#13#10+w);
    except on e: Exception do
      SendErrorMsg('TRTSPReceiver.SendPlay ('+Link.Host+') 522, StrNum='+StrNum+': '+e.ClassName+' - '+e.Message);
    end;
end;

function TRTSPReceiver.SendReceive(AText: AnsiString; Receive: boolean): string;
var
  ABytes,AResultBytes: TBytes;
  AnsiResult: AnsiString;
  w,sr: integer;
begin
  try
    result:='';
    if FSocket>0 then
    begin
      {$IFDEF UNIX}
      sr:=fpsend(FSocket,@AText[1],Length(AText),0);
      {$ELSE}
      sr:=send(FSocket,AText[1],Length(AText),0);
      {$ENDIF}
      if sr>0 then
      begin
        if Receive then
        begin
          SetLength(ABytes,1024);
          w:=1024;
          while w=1024 do
          begin
            {$IFDEF UNIX}
            w:=fprecv(FSocket,@ABytes[0],1024,0);
            {$ELSE}
            w:=recv(FSocket,ABytes[0],1024,0);
            {$ENDIF}
            if w>0 then
            begin
              SetLength(AResultBytes,length(AResultBytes)+w);
              Move(ABytes[0],AResultBytes[length(AResultBytes)-w],w);
            end
            else if w<0 then
              SendErrorMsg('TRTSPReceiver.SendReceive ('+Link.Host+') 560: '{$IFNDEF FPC}+SysErrorMessage(GetLastError){$ENDIF});
          end;
          if length(AResultBytes)>0 then
          begin
            SetLength(AnsiResult,length(AResultBytes));
            Move(AResultBytes[0],AnsiResult[1],length(AResultBytes));
            result:=string(AnsiResult);
          end;
        end;
      end
      else if sr<0 then
      begin
        {$IFNDEF FPC}
        w:=GetLastError;
        {$ENDIF}
        if w=10054 then
          result:='-10054'
        else
          SendErrorMsg('TRTSPReceiver.SendReceive ('+Link.Host+') 578: '+string(AText)+' - '+IntToStr({$IFDEF FPC}sr){$ELSE}w)+':'+SysErrorMessage(w){$ENDIF});
      end;
    end;
  except on e: Exception do
    SendErrorMsg('TRTSPReceiver.SendReceive ('+Link.Host+') 582: '+e.ClassName+' - '+e.Message);
  end;
end;

function TRTSPReceiver.SendReceiveMethod(AMethod, AURL, AHeadersText: AnsiString): string;
var
  ABytes: TBytes;
  authSeq,ht: AnsiString;
  w: integer;
  {$IFDEF FPC}
  Base64MidStream, Base64ResultStream: TStringStream;
  Base64EncodeStream: TBase64EncodingStream;
  {$ENDIF}
begin
  ht:=AnsiString(trim(string(AHeadersText)));
  if ht<>'' then
    ht:=ht+#13#10;
  if (realm<>'')and(nonce<>'') then
  begin
    authSeq:=AnsiString(GenerateAuthString(Link.Username,Link.Password,realm,string(AMethod),string(AURL),nonce));
    result:=SendReceive(AMethod+' '+AURL+' RTSP/1.0'#13#10+ht+'CSeq: '+CSeq+#13#10'Authorization: '+authSeq+#13#10'User-Agent: '+
        AnsiString(USER_AGENT)+#13#10#13#10,AMethod<>'SET_PARAMETER');
  end
  else
    result:=SendReceive(AMethod+' '+AURL+' RTSP/1.0'#13#10+ht+'CSeq: '+CSeq+#13#10'User-Agent: '+AnsiString(USER_AGENT)+#13#10#13#10,
        AMethod<>'SET_PARAMETER');
  //авторизация?
  if pos('401',copy(result,1,32))>0 then
  begin
    if (Link.Username<>'')and(Link.Password<>'') then
    begin
      //васик или дигест
      if pos('basic',LowerCase(result))>0 then
      begin
        {$IFDEF FPC}
        Base64MidStream:=TStringStream.Create(Link.Username+':'+Link.Password);
        try
          Base64ResultStream:=TStringStream.Create('');
          try
            Base64EncodeStream:=TBase64EncodingStream.Create(Base64ResultStream);
            try
              Base64EncodeStream.CopyFrom(Base64MidStream,Base64MidStream.Size);
              authSeq:='Basic '+AnsiString(Base64ResultStream.DataString);
            finally
              Base64EncodeStream.Free;
            end;
          finally
            Base64ResultStream.Free;
          end;
        finally
          Base64MidStream.Free;
        end;
        {$ELSE}
        authSeq:=AnsiString(Link.Username+':'+Link.Password);
        SetLength(ABytes,length(authSeq));
        move(authSeq[1],ABytes[0],length(authSeq));
        authSeq:='Basic '+AnsiString(TNetEncoding.Base64.EncodeBytesToString(ABytes));
        {$ENDIF}
      end
      else if pos('digest',LowerCase(result))>0 then
      begin
        w:=pos('digest realm',LowerCase(result));
        if w>0 then
        begin
          realm:=copy(result,w+14,64);
          w:=Pos('"',realm);
          if w>0 then
            delete(realm,w,64);
          w:=pos('nonce',LowerCase(result));
          if w>0 then
          begin
            nonce:=copy(result,w+7,64);
            w:=pos('"',nonce);
            if w>0 then
              delete(nonce,w,64);
            authSeq:=AnsiString(GenerateAuthString(Link.Username,Link.Password,realm,string(AMethod),string(AURL),nonce));
          end
          else
            SendErrorMsg('TRTSPReceiver.SendReceiveMethod ('+Link.Host+') 613: отсутствует digest nonce');
        end
        else
          SendErrorMsg('TRTSPReceiver.SendReceiveMethod ('+Link.Host+') 616: отсутствует digest realm');
      end;
      if authSeq<>'' then
      begin
        result:=SendReceive(AMethod+' '+AURL+' RTSP/1.0'#13#10+ht+'CSeq: '+CSeq+#13#10'Authorization: '+authSeq+#13#10'User-Agent: '+AnsiString(USER_AGENT)+#13#10#13#10);
        if pos('401',copy(result,1,32))>0 then
        begin
          SendErrorMsg('TRTSPReceiver.SendReceiveMethod ('+Link.Host+') 622: неправильный логин-пароль'#13#10+result);
          SetThisLastError('неправильный логин-пароль');
        end;
      end;
    end
    else
    begin
      SendErrorMsg('TRTSPReceiver.SendReceiveMethod ('+Link.Host+') 626: необходима авторизация');
      SetThisLastError('необходима авторизация');
    end;
  end;
end;

function TRTSPReceiver.SendSetParameter: string;
begin
  try
    result:=SendReceiveMethod('SET_PARAMETER',AnsiString(Link.GetFullURI),'');
  except on e: Exception do
    SendErrorMsg('TRTSPReceiver.SendSetParameter ('+Link.Host+') 693: '+e.ClassName+' - '+e.Message);
  end;
end;

function TRTSPReceiver.SendSetup: boolean;
var
  sl: TStringList;
  w,q: string;
  e: integer;
begin
  result:=false;
  try
    sl:=TStringList.Create;
    try
      w:=SendReceiveMethod('SETUP',TrackLink,'Transport: RTP/AVP/TCP;unicast;interleaved=0-1');
      sl.Text:=StringReplace(w,': ','=',[rfReplaceAll]);
      //ищем сессию
      w:=trim(sl.Values['Session']);
      if w<>'' then
      begin
        e:=pos(';',w);
        if e>0 then
        begin
          q:=copy(w,1,e-1);
          //если это таймаут, то перепосылать команду проигрывания
          w:=copy(w,e+1,1024);
          if copy(w,1,8)='timeout=' then
            PingInterval:=StrToIntDef(copy(w,9,1024),60)*1000;
        end
        else
          q:=w;
        CurSession:=AnsiString(q);
        result:=CurSession<>'';
        if not result then
          SendErrorMsg('TRTSPReceiver.SendSetup ('+Link.Host+') 727: нет сессии в параметре сессии'#13#10+sl.Text);
      end
      else
        SendErrorMsg('TRTSPReceiver.SendSetup ('+Link.Host+') 730: нет сессии в ответе, TrackLink='+string(TrackLink)+#13#10+sl.Text);
    finally
      FreeAndNil(sl);
    end;
  except on e: Exception do
    SendErrorMsg('TRTSPReceiver.SendSetup ('+Link.Host+') 735: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TRTSPReceiver.SendTeardown;
var
  StrNum: string;
begin
  try
    StrNum:='737';
    if assigned(LogicPing) then
    begin
      StrNum:='740';
      LogicPing.FParent:=nil;
      LogicPing.Stop;
      LogicPing:=nil;
    end;
    StrNum:='745';
    SendReceiveMethod('TEARDOWN',AnsiString(Link.GetFullURI),'');
    StrNum:='747';
    TCPReader.Stop;
  except on e: Exception do
    SendErrorMsg('TRTSPReceiver.SendTeardown 750: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TRTSPReceiver.SetActive(const Value: boolean);
var
  StrNum: string;
begin
  FLock.Enter;
  try
    try
      StrNum:='761';
      if Value then
      begin
        if FConnectionString='' then
          SendErrorMsg('TRTSPReceiver::SetActive 765: no connection string')
        else
        begin
          StrNum:='768';
          if not TCPReader.Active then
            Connect;
        end;
      end
      else
      begin
        StrNum:='775';
        SendTeardown;
      end;
    except on e: Exception do
      SendErrorMsg('TRTSPReceiver.SetActive 779, StrNum='+StrNum+': '+e.ClassName+' - '+e.Message);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TRTSPReceiver.SetConnectionString(const Value: string);
begin
  FLock.Enter;
  try
    FConnectionString:=Value;
    if FConnectionString<>'' then
      Link.Apply(Value);
  finally
    FLock.Leave;
  end;
end;

procedure TRTSPReceiver.SetThisLastError(ALastError: string);
begin
  FLock.Enter;
  try
    FLastError:=ALastError;
  finally
    FLock.Leave;
  end;
end;

procedure TRTSPReceiver.SetOutputQueue(Queue: TBaseQueue);
begin
  RTSPParser.SetOutputQueue(Queue);
end;

end.
