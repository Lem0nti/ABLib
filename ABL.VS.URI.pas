unit ABL.VS.URI;

interface

type
  TURI=class
  public
    QueryString, Path, Protocol, Host, Port, Username, Password: string;
    function GetFullURI: string;
    procedure Apply(AURL: string);
  end;

implementation

{ TURI }

procedure TURI.Apply(AURL: string);
var
  QueryStart,ProtocolEnd,PassFinish,UserFinish,PathStart,HostEnd: integer;
  tmpUrl: string;
begin
  QueryString:='';
  Path:='';
  Protocol:='';
  Host:='';
  Port:='';
  Username:='';
  Password:='';
  //начало запроса
  QueryStart:=Pos('?',AURL);
  ProtocolEnd:=Pos(':',AURL);
  if ProtocolEnd>0 then  //протокол может быть не указан
    if (length(AURL)>(ProtocolEnd+3))and(Copy(AURL,ProtocolEnd,3)='://') then
    begin
      Protocol:=Copy(AURL,1,ProtocolEnd-1);
      ProtocolEnd:=ProtocolEnd+3
    end;
  tmpUrl:=copy(AURL,ProtocolEnd,1024);
  PassFinish:=Pos('@',tmpUrl);
  if PassFinish>0 then  //пользователь-пароль могут быть не указаны
  begin
    UserFinish:=Pos(':',tmpUrl);
    if UserFinish<PassFinish then
    begin
      Username:=Copy(tmpUrl,1,UserFinish-1);
      Password:=Copy(tmpUrl,UserFinish+1,PassFinish-UserFinish-1);
    end;
  end;
  tmpUrl:=copy(tmpUrl,PassFinish+1,1024);
  PathStart:=Pos('/',tmpUrl);
  if PathStart>0 then
    Host:=Copy(tmpUrl,1,PathStart-1)
  else
    Host:=tmpUrl;
  HostEnd:=Pos(':',Host);
  if HostEnd>0 then
  begin
    Port:=Copy(Host,HostEnd+1,6);
    Delete(Host,HostEnd,1024);
  end;
  if QueryStart>0 then
    QueryString:=Copy(AURL,QueryStart,1024);
  if PathStart>0 then
  begin
    Path:=Copy(tmpUrl,PathStart,1024);
    QueryStart:=Pos('?',Path);
    if QueryStart>0 then
      Delete(Path,QueryStart,1024);
  end;
end;

function TURI.GetFullURI: string;

  function ifthen(AValue: boolean; ATrue: string; AFalse: string = ''): string;
  begin
    if AValue then
      result:=ATrue
    else
      result:=AFalse;
  end;

begin
  result:=Protocol+'://'+Host+ifthen(Port<>'',':'+Port)+Path+QueryString;
end;

end.
