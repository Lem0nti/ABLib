unit ABL.IO.NetworkReader;

interface

uses
  ABL.IO.Reader, {$IFDEF UNIX}sockets{$ELSE}WinSock{$ENDIF}, ABL.Core.BaseQueue, SysUtils, Types, SyncObjs;

type
  TNetworkReader=class(TReader)
  private
    function GetPort: Word;
    function GetSocket: TSocket;
    procedure SetPort(const Value: Word);
    procedure SetSocket(const Value: TSocket);
  protected
    FPort: Word;
    FSocket: TSocket;
  public
    constructor Create(AOutputQueue: TBaseQueue; AName: string = ''; ASocket: TSocket = 0); reintroduce; virtual;
    procedure Stop; override;
    property Port: Word read GetPort write SetPort;
    property Socket: TSocket read GetSocket write SetSocket;
  end;

implementation

{ TNetworkReader }

constructor TNetworkReader.Create(AOutputQueue: TBaseQueue; AName: string = ''; ASocket: TSocket = 0);
var
  {$IFDEF MSWINDOWS}
  vWSAData: TWSAData;
  Addr: TSockAddrIn;
  {$ELSE}
  Addr: TInetSockAddr;
  {$ENDIF}
  hRes: integer;
  Size: integer;
begin
  inherited Create(AOutputQueue,AName);
  FSocket:=ASocket;
  {$IFDEF MSWINDOWS}
  hRes:=WSAStartup($101,vWSAData);
  if hRes<>0 then
    RaiseLastOSError;
  {$ENDIF}
  if FSocket>0 then
  begin
    Size := sizeof(Addr);
    {$IFDEF UNIX}
    fpgetsockname(FSocket,@Addr,@Size);
    {$ELSE}
    getsockname(FSocket,Addr,Size);
    {$ENDIF}
    FPort:=ntohs(Addr.sin_port);
    inherited Start;
  end;
end;

function TNetworkReader.GetPort: Word;
begin
  FLock.Enter;
  try
    result:=FPort;
  finally
    FLock.Leave;
  end;
end;

function TNetworkReader.GetSocket: TSocket;
begin
  FLock.Enter;
  try
    result:=FSocket;
  finally
    FLock.Leave;
  end;
end;

procedure TNetworkReader.SetPort(const Value: Word);
var
  NeedStart: boolean;
begin
  FLock.Enter;
  try
    if FPort<>Value then
    begin
      NeedStart:=false;
      if Active then
      begin
        Stop;
        NeedStart:=true;
      end;
      FPort:=Value;
      if NeedStart then
          Start;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TNetworkReader.SetSocket(const Value: TSocket);
var
  Addr: {$IFDEF UNIX}TInetSockAddr{$ELSE}TSockAddrIn{$ENDIF};
  Size: integer;
begin
  FLock.Enter;
  try
    if FSocket<>Value then
    begin
      Stop;
      FSocket:=Value;
      Size := sizeof(Addr);
      {$IFDEF UNIX}
      fpgetsockname(FSocket,@Addr,@Size);
      {$ELSE}
      getsockname(FSocket,Addr,Size);
      {$ENDIF}
      FPort:=ntohs(Addr.sin_port);
      inherited Start;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TNetworkReader.Stop;
begin
  SubThread:=nil;
  closesocket(FSocket);
  inherited;
end;

end.
