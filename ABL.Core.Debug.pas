unit ABL.Core.Debug;

interface

uses
  Windows, Classes, System.SysUtils, IniFiles;

type
  PDebugKey = ^TDebugKey;
  TDebugKey = record
    Name: ShortString;
    Value: boolean;
  end;

  TDebug = class
  private
    KeyList: TList;
    FLock: TRTLCriticalSection;
    procedure SaveMsg(AKey,AMsg,AFileName: string);
  public
    Constructor Create;
    Destructor Destroy; override;
    procedure SaveLogMsg(AKey,AMsg: string);
    procedure SaveTextMsg(AKey,AMsg: string);
  end;

var
  Debug: TDebug;

/// <summary>
///  Сохранение отладочного сообщения при включённом ключе Debug. Файл лога: [имя исполняемого файла]_log\[ГГГГММДД].log
/// </summary>
///  <param name="AMessage: string">
///  Текст, подлежащий записи
///  </param>
procedure SendDebugMsg(AMessage: string);
/// <summary>
///  Сохранение отладочного сообщения при включённом ключе Error (по умолчанию включён). Файл лога: [имя исполняемого файла]_log\[ГГГГММДД].log
/// </summary>
///  <param name="AMessage: string">
///  Текст, подлежащий записи
///  </param>
procedure SendErrorMsg(AMessage: string);
/// <summary>
///  Сохранение отладочного сообщения при включённом ключе Performance (по умолчанию выключен). Файл лога: [имя исполняемого файла]_log\[ГГГГММДД].log
/// </summary>
///  <param name="AMessage: string">
///  Текст, подлежащий записи
///  </param>
procedure SendPerformanceMsg(AMessage: string);
/// <summary>
///  Сохранение отладочного сообщения при включённом ключе TCP. Файл лога: [имя исполняемого файла]_log\[ГГГГММДД].txt
/// </summary>
///  <param name="AMessage: string">
///  Текст, подлежащий записи
///  </param>
procedure SendTCPMsg(AMessage: string);
/// <summary>
///  Сохранение отладочного сообщения при включённом ключе TXT. Файл лога: [имя исполняемого файла]_log\[ГГГГММДД].txt
/// </summary>
///  <param name="AMessage: string">
///  Текст, подлежащий записи
///  </param>
procedure SendTextToTXT(AMessage: string);
/// <summary>
///  Сохранение отладочного сообщения при включённом ключе Timer. Файл лога: [имя исполняемого файла]_log\[ГГГГММДД].log
/// </summary>
///  <param name="AMessage: string">
///  Текст, подлежащий записи
///  </param>
procedure SendTimerMsg(AMessage: string);

implementation

procedure SendDebugMsg(AMessage: string);
begin
  if assigned(Debug) then
    Debug.SaveLogMsg('DEBUG',AMessage)
end;

procedure SendErrorMsg(AMessage: string);
begin
  if assigned(Debug) then
    Debug.SaveLogMsg('ERROR',AMessage);
end;

procedure SendPerformanceMsg(AMessage: string);
begin
  if assigned(Debug) then
    Debug.SaveLogMsg('PERFORMANCE',AMessage);
end;

procedure SendTCPMsg(AMessage: string);
begin
  if assigned(Debug) then
    Debug.SaveTextMsg('TCP',AMessage);
end;

procedure SendTextToTXT(AMessage: string);
begin
  if assigned(Debug) then
    Debug.SaveTextMsg('TXT',AMessage);
end;

procedure SendTimerMsg(AMessage: string);
begin
  if assigned(Debug) then
    Debug.SaveLogMsg('TIMER',AMessage);
end;

{ TDebug }

constructor TDebug.Create;
var
  sl: TStringList;
  q: integer;
  Key: PDebugKey;
begin
  inherited;
  InitializeCriticalSection(FLock);
  KeyList:=TList.Create;
  sl:=TStringList.Create;
  try
    with TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
      try
        ReadSectionValues('DEBUG',sl);
      finally
        Free;
      end;
    sl.Values['ERROR']:='1';
    for q:= 0 to sl.Count - 1 do
    begin
      New(Key);
      Key.Name:=ShortString(UpperCase(sl.Names[q]));
      Key.Value:=sl.ValueFromIndex[q]='1';
      KeyList.Add(Key);
    end;
  finally
    FreeAndNil(sl);
  end;
end;

destructor TDebug.Destroy;
begin
  Debug:=nil;
  if assigned(KeyList) then
    FreeAndNil(KeyList);
  DeleteCriticalSection(FLock);
  inherited;
end;

procedure TDebug.SaveLogMsg(AKey, AMsg: string);
begin
  SaveMsg(AKey,AMsg,ChangeFileExt(ParamStr(0),'.log'));
end;

procedure TDebug.SaveMsg(AKey,AMsg,AFileName: string);
var
  TxtFile: Text;
  q: integer;
  dk: PDebugKey;
  fn: TFileName;
  TheFileName: array[0..MAX_PATH] of char;
begin
  EnterCriticalSection(FLock);
  try
    if trim(AMsg)<>'' then
      for q := 0 to KeyList.Count - 1 do
      begin
        dk:=PDebugKey(KeyList.Items[q]);
        if dk.Value and (dk.Name=ShortString(AKey)) then
        begin
          //ищем папку
          try
            fn:=ChangeFileExt(AFileName,'_log');
            ForceDirectories(fn);
            fn:=fn+'\'+FormatDateTime('YYYYMMDD',now)+ExtractFileExt(AFileName);
            Assign(TxtFile,fn);
            if not FileExists(fn) then
              Rewrite(TxtFile)
            else
              Append(TxtFile);
            FillChar(TheFileName, sizeof(TheFileName), #0);
            GetModuleFileName(hInstance, TheFileName, sizeof(TheFileName));
            Writeln(TxtFile,AKey+' '+DateTimeToStr(now)+' '+ExtractFileName(trim(TheFileName))+' '+AMsg);
            Close(TxtFile);
          except
          end;
          break;
        end;
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TDebug.SaveTextMsg(AKey, AMsg: string);
begin
  SaveMsg(AKey,AMsg,ChangeFileExt(ParamStr(0),'.txt'));
end;

initialization
  Debug:=TDebug.Create;

finalization
  if assigned(Debug) then
    FreeAndNil(Debug);

end.
