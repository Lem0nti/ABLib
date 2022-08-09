unit ABL.Core.BaseObject;

interface

uses
  SyncObjs, SysUtils;

type
  //TBaseObject=class;
  /// <summary>
  /// Базовый класс ABL. Обеспечивает базовый функционал ABL: имя и ИД экземпляра класса, методы блокировки и выхода из блокировки, связь с родителем
  /// </summary>
  TBaseObject=class
  private
    function GetID: Cardinal;
    function GetName: string;
    function GetParent: TBaseObject;
    procedure SetParent(const Value: TBaseObject);
    procedure SetName(const Value: string);
  protected
    FID: Cardinal;
    FLock: TCriticalSection;
    FName: string;
    FParent: TBaseObject;
  public
    /// <summary>
    /// Конструктор. Виртуальный.
    /// </summary>
    /// <param name="AName: string">
    /// Имя объекта
    /// </param>
    constructor Create(AName: string = ''); virtual;
    destructor Destroy; override;
    procedure ChildCB(AChild: TBaseObject); virtual;
    procedure Lock;
    procedure Unlock;
    property ID: Cardinal read GetID;
    property Name: string read GetName write SetName;
    property Parent: TBaseObject read GetParent write SetParent;
  end;

implementation

var
  GlobID: Cardinal = 0;

{ TRCLBaseObject }

procedure TBaseObject.ChildCB(AChild: TBaseObject);
begin

end;

constructor TBaseObject.Create(AName: string);
begin
  FLock:=TCriticalSection.Create;
  inc(GlobID);
  FID:=GlobID;
  FName:=AName;
end;

destructor TBaseObject.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TBaseObject.GetID: Cardinal;
begin
  FLock.Enter;
  try
    result:=FID;
  finally
    FLock.Leave;
  end;
end;

function TBaseObject.GetName: string;
begin
  FLock.Enter;
  try
    result:=FName;
  finally
    FLock.Leave;
  end;
end;

function TBaseObject.GetParent: TBaseObject;
begin
  FLock.Enter;
  try
    result:=FParent;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObject.Lock;
begin
  FLock.Enter;
end;

procedure TBaseObject.SetName(const Value: string);
begin
  FName:=Value;
end;

procedure TBaseObject.SetParent(const Value: TBaseObject);
begin
  FLock.Enter;
  try
    FParent:=Value;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObject.Unlock;
begin
  FLock.Leave;
end;

end.
