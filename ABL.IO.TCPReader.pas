unit ABL.IO.TCPReader;

interface

uses
  ABL.IO.NetworkReader, ABL.IO.Reader, ABL.Core.BaseQueue, {$IFDEF UNIX}sockets{$ELSE}WinSock{$ENDIF}, SysUtils,
  ABL.Core.Debug, ABL.IO.IOTypes, DateUtils, Classes, Generics.Collections;

type
  TConnectionReader=class;

  TTCPReader=class(TNetworkReader)
  private
    ThreadPool: TList<TConnectionReader>;
  protected
    procedure Execute; override;
  public
    constructor Create(AOutputQueue: TBaseQueue; AName: string = ''; ASocket: TSocket = 0); override;
    destructor Destroy; override;
    procedure SetAcceptedSocket(ASocket: TSocket);
    procedure Start; override;
  end;

  TConnectionReader=class(TThread)
  private
    FMaxBuffer: Cardinal;
    FOutputQueue: TBaseQueue;
    FSocket: TSocket;
  protected
    procedure Execute; override;
  public
    FReader: TTCPReader;
    Constructor Create(ASocket: TSocket; AOutputQueue: TBaseQueue; AMaxBuffer: Cardinal;
        AReader: TTCPReader); reintroduce;
  end;

implementation

{ TTCPReader }

constructor TTCPReader.Create(AOutputQueue: TBaseQueue; AName: string; ASocket: TSocket);
begin
  inherited Create(AOutputQueue,AName,ASocket);
  ThreadPool:=TList<TConnectionReader>.Create;
end;

destructor TTCPReader.Destroy;
var
  ConnectionReader: TConnectionReader;
begin
  for ConnectionReader in ThreadPool do
  begin
    ConnectionReader.FReader:=nil;
    ConnectionReader.Terminate;
  end;
  ThreadPool.Free;
  inherited;
end;

procedure TTCPReader.Execute;
var
  S1: TSocket;
  Addr: TSockAddr;
begin
  while not Terminated do
  begin
    //Ожидаем подключения
    {$IFDEF UNIX}
    S1:=fpaccept(FSocket,@Addr,nil);
    {$ELSE}
    S1:=accept(FSocket,@Addr,nil);
    {$ENDIF}
    if S1<0 then
    begin
      SendErrorMsg('TTCPReader.Execute 75: '+{$IFDEF FPC}'S1='+IntToStr(S1){$ELSE}SysErrorMessage(GetLastError){$ENDIF});
      SubThread.Terminate;
      FTerminated:=true;
      break;
    end;
    if Terminated then
      break;
    SetAcceptedSocket(S1);
  end;
end;


procedure TTCPReader.SetAcceptedSocket(ASocket: TSocket);
begin
  ThreadPool.Add(TConnectionReader.Create(ASocket,FOutputQueue,FMaxBuffer,Self));
end;

procedure TTCPReader.Start;
var
  hRes: Integer;
  vSockAddr : TSockAddr;
begin
  //Создаем прослушивающий сокет.
  {$IFDEF UNIX}
  FSocket := fpsocket(AF_INET,SOCK_STREAM,IPPROTO_IP);
  {$ELSE}
  FSocket := WinSock.socket(AF_INET,SOCK_STREAM,IPPROTO_IP);
  {$ENDIF}
  if FSocket = INVALID_SOCKET then
  begin
    SendErrorMsg('TTCPReader.Start 105: '+{$IFDEF FPC}'FSocket='+IntToStr(FSocket){$ELSE}SysErrorMessage(GetLastError){$ENDIF});
    exit;
  end;
  FillChar(vSockAddr,SizeOf(TSockAddr),0);
  vSockAddr.sin_family := AF_INET;
  vSockAddr.sin_port := htons(FPort);
  vSockAddr.sin_addr.S_addr := INADDR_ANY;
  //Привязываем адрес и порт к сокету.
  {$IFDEF UNIX}
  hRes:=fpbind(FSocket,@vSockAddr,SizeOf(TSockAddr));
  {$ELSE}
  hRes:=bind(FSocket,vSockAddr,SizeOf(TSockAddr));
  {$ENDIF}
  if hRes<>0 then
  begin
    SendErrorMsg('TTCPReader.Start 120: ['+IntToStr(hRes)+'] '{$IFNDEF FPC}+SysErrorMessage(GetLastError){$ENDIF});
    exit;
  end;
  //Начинаем прослушивать
  {$IFDEF UNIX}
  hRes:=fplisten(FSocket,SOMAXCONN);
  {$ELSE}
  hRes:=listen(FSocket,SOMAXCONN);
  {$ENDIF}
  if hRes<>0 then
  begin
    SendErrorMsg('TTCPReader.Start 131: ['+IntToStr(hRes)+'] '{$IFNDEF FPC}+SysErrorMessage(GetLastError){$ENDIF});
    exit;
  end;
  inherited Start;
end;

{ TConnectionReader }

constructor TConnectionReader.Create(ASocket: TSocket; AOutputQueue: TBaseQueue; AMaxBuffer: Cardinal;
    AReader: TTCPReader);
begin
  inherited Create(False);
  FSocket:=ASocket;
  FOutputQueue:=AOutputQueue;
  FMaxBuffer:=AMaxBuffer;
  FReader:=AReader;
end;

procedure TConnectionReader.Execute;
var
  ABytes: TBytes;
  AResultBytes: TBytes;
  w: integer;
  NTime: int64;
  ReadedData: PDataFrame;
  tmpLTimeStamp: TTimeStamp;
  StrNum: string;
begin
  FreeOnTerminate:=true;
  try
    StrNum:='161';
    try
      SetLength(ABytes,1024);
      SetLength(AResultBytes,0);
      NTime:=0;
      while not Terminated do
      begin
        StrNum:='168';
        w:=1024;
        while w=1024 do
        begin
          StrNum:='172';
          if Terminated then
            break;
          {$IFDEF UNIX}
          w:=fprecv(FSocket,@ABytes[0],1024,0);
          {$ELSE}
          w:=recv(FSocket,ABytes[0],1024,0);
          {$ENDIF}
          if NTime=0 then
          begin
            StrNum:='182';
            tmpLTimeStamp := DateTimeToTimeStamp(now);
            NTime:=tmpLTimeStamp.Date*Int64(MSecsPerDay)+tmpLTimeStamp.Time-UnixTimeStart;
          end;
          if Terminated then
            break;
          if w=INVALID_SOCKET then
          begin
            StrNum:='190';
            if (not Terminated) and assigned(FReader)  then
            begin
              StrNum:='193';
              {$IFDEF UNIX}
              SendErrorMsg('TConnectionReader.Execute 188: INVALID_SOCKET '+IntToStr(w));
              {$ELSE}
              w:=WSAGetLastError;
              if w<>10053 then  //graceful
                SendErrorMsg('TConnectionReader.Execute 192: INVALID_SOCKET '+IntToStr(w)+' - '+SysErrorMessage(w));
              {$ENDIF}
            end;
            break;
          end
          else if w>0 then
          begin
            StrNum:='206';
            SetLength(AResultBytes,length(AResultBytes)+w);
            Move(ABytes[0],AResultBytes[length(AResultBytes)-w],w);
            if (FMaxBuffer>0) and (length(AResultBytes)>=FMaxBuffer) then
              break;
          end;
        end;
        if (w>0) and (length(AResultBytes)>0) then
        begin
          StrNum:='215';
          new(ReadedData);
          ReadedData^.Time:=NTime;
          ReadedData^.Reserved:=0;
          ReadedData^.Size:=length(AResultBytes);
          GetMem(ReadedData^.Data,ReadedData^.Size);
          Move(AResultBytes[0],ReadedData^.Data^,length(AResultBytes));
          if assigned(FReader) then
            FReader.IncTraffic(ReadedData^.Size)
          else
            break;
          FOutputQueue.Push(ReadedData);
          SetLength(AResultBytes,0);
          NTime:=0;
        end
        else
        begin
          StrNum:='232';
          if not Terminated then
            SendErrorMsg('TConnectionReader.Execute 224: соединение закрыто '+IntToStr(ThreadID));
          break;
        end;
      end;
      StrNum:='238';
      if assigned(FReader) then
        FReader.ThreadPool.Remove(Self);
    except on e: Exception do
      SendErrorMsg('TConnectionReader.Execute 242, StrNum='+StrNum+': ('+IntToStr(ThreadID)+') '+e.ClassName+' - '+e.Message);
    end;
  finally
    Terminate;
  end;
end;

end.
