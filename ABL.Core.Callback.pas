unit ABL.Core.Callback;

interface

uses
  ABL.Core.DirectThread, ABL.Core.BaseQueue, SysUtils;

type
  TDoExecuteCallbackMethod = procedure(var AInputData: Pointer) of object;

  TCallback=class(TDirectThread)
  private
    FDoExecuteCallbackMethod: TDoExecuteCallbackMethod;
    function GetOnExecute: TDoExecuteCallbackMethod;
    procedure SetOnExecute(const Value: TDoExecuteCallbackMethod);
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue: TBaseQueue; AName: string = ''); reintroduce;
    destructor Destroy; override;
    property OnExecute: TDoExecuteCallbackMethod read GetOnExecute write SetOnExecute;
  end;

implementation

{ TCallback }

{ TCallback }

constructor TCallback.Create(AInputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,nil,AName);
  Start;
end;

destructor TCallback.Destroy;
begin
  FLock.Enter;
  try
    FDoExecuteCallbackMethod:=nil;
  finally
    FLock.Leave;
  end;
  inherited Destroy;
end;

procedure TCallback.DoExecute(var AInputData, AResultData: Pointer);
begin
  FLock.Enter;
  try
    if assigned(FDoExecuteCallbackMethod) then
      FDoExecuteCallbackMethod(AInputData);
  finally
    FLock.Leave;
  end;
end;

function TCallback.GetOnExecute: TDoExecuteCallbackMethod;
begin
  result:=FDoExecuteCallbackMethod;
end;

procedure TCallback.SetOnExecute(const Value: TDoExecuteCallbackMethod);
begin
  FLock.Enter;
  try
    FDoExecuteCallbackMethod:=Value;
  finally
    FLock.Leave;
  end;
end;

end.
