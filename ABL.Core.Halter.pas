unit ABL.Core.Halter;

interface

uses
  ABL.Core.TimerThread, PsAPI, Windows, ABL.Core.Debug, SysUtils;

type
  THalter=class(TTimerThread)
  private
    FMemoryLimit: Cardinal;
    function GetMemoryLimit: Cardinal;
    procedure SetMemoryLimit(const Value: Cardinal);
  protected
    procedure DoExecute; override;
    procedure DoReceive(var AInputData: Pointer); override;
  public
    constructor Create(ATimeOut: Cardinal = 20000; AMemoryLimit: Cardinal = 256); reintroduce;
    property MemoryLimit: Cardinal read GetMemoryLimit write SetMemoryLimit;
  end;

var
  Halter: THalter;

implementation

{ THalter }

constructor THalter.Create(ATimeOut: Cardinal; AMemoryLimit: Cardinal);
begin
  inherited Create(nil,nil,'THalter');
  FInterval:=ATimeOut;
  FMemoryLimit:=AMemoryLimit;
  Enabled:=true;
  Active:=true;
end;

procedure THalter.DoExecute;
var
  cb: integer;
  pmc: PPROCESS_MEMORY_COUNTERS;
  CurMem: integer;
begin
  cb:=SizeOf(_PROCESS_MEMORY_COUNTERS);
  GetMem(pmc,cb);
  try
    pmc^.cb:=cb;
    if GetProcessMemoryInfo(GetCurrentProcess,pmc,cb) then
    begin
      CurMem:=pmc^.WorkingSetSize div (1024*1024);
      FBaseThreadLock.Enter;
      if CurMem>FMemoryLimit then
      begin
        SendErrorMsg('THalter.DoExecute 54, использование ОЗУ: '+IntToStr(CurMem)+' Mb, перезапуск');
        Halt;
      end;
      FBaseThreadLock.Leave;
    end;
  finally
    FreeMem(pmc);
  end;
end;

procedure THalter.DoReceive(var AInputData: Pointer);
begin
end;

function THalter.GetMemoryLimit: Cardinal;
begin
  FBaseThreadLock.Enter;
  result:=FMemoryLimit;
  FBaseThreadLock.Leave;
end;

procedure THalter.SetMemoryLimit(const Value: Cardinal);
begin
  FBaseThreadLock.Enter;
  FMemoryLimit:=Value;
  FBaseThreadLock.Leave;
end;

end.
