unit ABL.IO.TCPReader;

interface

uses
  ABL.IO.NetworkReader, ABL.IO.Reader, ABL.Core.BaseQueue, {$IFDEF UNIX}sockets{$ELSE}WinSock{$ENDIF}, SysUtils,
  ABL.Core.Debug, ABL.IO.IOTypes, DateUtils, Classes, Generics.Collections;

type
  TConnectionReader=class;

  {$IFDEF FPC}
  TConnectionList = specialize {$IFDEF UNIX}TFPGObjectList{$ELSE}TObjectList{$ENDIF}<TConnectionReader>;
  {$ENDIF}

  TTCPReader=class(TNetworkReader)
  private
    ThreadPool: {$IFDEF FPC}TConnectionList{$ELSE}TObjectList<TConnectionReader>{$ENDIF};
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
  ThreadPool:={$IFDEF FPC}TConnectionList{$ELSE}TObjectList<TConnectionReader>{$ENDIF}.Create;
  ThreadPool.{$IFDEF UNIX}FreeObjects{$ELSE}OwnsObjects{$ENDIF}:=false;
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
  ReadedData: TTimedDataHeader;
  OutputData: Pointer;
  tmpLTimeStamp: TTimeStamp;
  StrNum: string;
begin
  FreeOnTerminate:=true;
  try
    StrNum:='167';
    try
      SetLength(ABytes,1024);
      SetLength(AResultBytes,0);
      NTime:=0;
      ReadedData.DataHeader.Magic:=16961;
      ReadedData.DataHeader.DataType:=1;
      ReadedData.DataHeader.Version:=0;
      ReadedData.Reserved:=0;
      while not Terminated do
      begin
        w:=1024;
        while w=1024 do
        begin
          if Terminated then
            break;
          {$IFDEF UNIX}
          w:=fprecv(FSocket,@ABytes[0],1024,0);
          {$ELSE}
          w:=recv(FSocket,ABytes[0],1024,0);
          {$ENDIF}
          if NTime=0 then
          begin
            tmpLTimeStamp := DateTimeToTimeStamp(now);
            NTime:=tmpLTimeStamp.Date*Int64(MSecsPerDay)+tmpLTimeStamp.Time-UnixTimeStart;
          end;
          if Terminated then
            break;
          if w=INVALID_SOCKET then
          begin
            if (not Terminated) and assigned(FReader)  then
            begin
              {$IFDEF UNIX}
              SendErrorMsg('TConnectionReader.Execute 201: INVALID_SOCKET '+IntToStr(w));
              {$ELSE}
              w:=WSAGetLastError;
              if w<>10053 then  //graceful
                SendErrorMsg('TConnectionReader.Execute 205: INVALID_SOCKET '+IntToStr(w)+' - '+SysErrorMessage(w));
              {$ENDIF}
            end;
            break;
          end
          else if w>0 then
          begin
            SetLength(AResultBytes,length(AResultBytes)+w);
            Move(ABytes[0],AResultBytes[length(AResultBytes)-w],w);
            if (FMaxBuffer>0) and (length(AResultBytes)>=FMaxBuffer) then
              break;
          end;
        end;
        if (w>0) and (length(AResultBytes)>0) then
        begin
          ReadedData.Time:=NTime;
          ReadedData.DataHeader.Size:=length(AResultBytes)+SizeOf(TTimedDataHeader);
          GetMem(OutputData,ReadedData.DataHeader.Size);
          Move(ReadedData,OutputData^,SizeOf(TTimedDataHeader));
          Move(AResultBytes[0],PByte(NativeUInt(OutputData)+SizeOf(TTimedDataHeader))^,length(AResultBytes));
          if assigned(FReader) then
            FReader.IncTraffic(length(AResultBytes))
          else
            break;
          FOutputQueue.Push(OutputData);
          SetLength(AResultBytes,0);
          NTime:=0;
        end
        else
        begin
          StrNum:='233';
          if not Terminated then
            SendErrorMsg('TConnectionReader.Execute 235: соединение закрыто '+IntToStr(ThreadID));
          break;
        end;
      end;
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
