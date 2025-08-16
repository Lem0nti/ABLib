unit ABL.Core.Lib;

interface

uses
  ABL.Core.DirectThread, ABL.Core.CoreTypes, ABL.Core.BaseQueue, Windows, ABL.Core.Debug, SysUtils;

type
  TLib=class(TDirectThread)
  private
    FDeleteInstance,FDoExecuteProc: TPointerMethod;
    FGetInstance: TPointerFunction;
    FSetParamProc: TSetParamProc;
    FHandle: THandle;
    Instance: Pointer;
    FFileName, FParamList: string;
    function GetFileName: string;
    function GetParamList: string;
    procedure SetFileName(const Value: string);
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    destructor Destroy; override;
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
    procedure SetParam(Param: WideString; Value: WideString);
    property FileName: string read GetFileName write SetFileName;
    property ParamList: string read GetParamList;
  end;

implementation

{ TLib }

constructor TLib.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited;
  FHandle:=0;
  FParamList:='';
end;

destructor TLib.Destroy;
begin
  if FHandle>0 then
    FreeLibrary(FHandle);
  inherited;
end;

procedure TLib.DoExecute(var AInputData, AResultData: Pointer);
begin
  FBaseThreadLock.Enter;
  try
    if ((FHandle>0) and assigned(FDoExecuteProc)) then
      FDoExecuteProc(AInputData,AResultData,Instance);
  except on e: Exception do
    SendErrorMsg('TLib.DoExecute 54 '+FFileName+': '+e.ClassName+' - '+e.Message);
  end;
  FBaseThreadLock.Leave;
end;

function TLib.GetFileName: string;
begin
  FBaseThreadLock.Enter;
  result:=FFileName;
  FBaseThreadLock.Leave;
end;

function TLib.GetParamList: string;
begin
  FBaseThreadLock.Enter;
  result:=FParamList;
  FBaseThreadLock.Leave;
end;

procedure TLib.SetFileName(const Value: string);
begin
  FBaseThreadLock.Enter;
  if FFileName<>Value then
  begin
    if FHandle>0 then
    begin
      FreeLibrary(FHandle);
      FHandle:=0;
    end;
    if FileExists(FFileName) then
    begin
      FHandle:=LoadLibrary(FFileName);
      @FDeleteInstance:=GetProcAddress(FHandle,'DeleteInstance');
      @FDoExecuteProc:=GetProcAddress(FHandle,'DoExecuteProc');
      @FGetInstance:=GetProcAddress(FHandle,'GetInstance');
      @FSetParamProc:=GetProcAddress(FHandle,'SetParamProc');
      Instance=FGetInstance;
    end
    else
      SendErrorMsg('TLib.SetFileName 92 '+FFileName+': файл отсутствует');
  end;
  FBaseThreadLock.Leave;
end;

procedure TLib.SetParam(Param, Value: WideString);
begin
  FBaseThreadLock.Enter;
  try
    if ((FHandle>0) and assigned(FSetParamProc)) then
      FSetParamProc(Param,Value,Instance);
  except on e: Exception do
    SendErrorMsg('TLib.SetParam 105 '+FFileName+': '+e.ClassName+' - '+e.Message);
  end;
  FBaseThreadLock.Leave;
end;

end.
