unit ABL.IO.Reader;

interface

uses
  ABL.Core.BaseThread, ABL.Core.BaseQueue;

type
  TReader=class(TBaseThread)
  private
    function GetMaxBuffer: Cardinal;
    function GetReadSize: Cardinal;
    procedure SetMaxBuffer(const Value: Cardinal);
  protected
    FMaxBuffer,FReadSize: Cardinal;
    procedure IncTraffic(ASize: Cardinal);
  public
    constructor Create(AOutputQueue: TBaseQueue; AName: string = ''); reintroduce;
    property MaxBuffer: Cardinal read GetMaxBuffer write SetMaxBuffer;
    property ReadSize: Cardinal read GetReadSize;
  end;

implementation

{ TReader }

constructor TReader.Create(AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(nil,AOutputQueue,AName);
  FReadSize:=0;
  FMaxBuffer:=1024*1024;
end;

function TReader.GetMaxBuffer: Cardinal;
begin
  Lock;
  try
    result:=FMaxBuffer;
  finally
    Unlock;
  end;
end;

function TReader.GetReadSize: Cardinal;
begin
  Lock;
  try
    result:=FReadSize;
  finally
    Unlock;
  end;
end;

procedure TReader.IncTraffic(ASize: Cardinal);
begin
  Lock;
  try
    FReadSize:=FReadSize+ASize;
  finally
    Unlock;
  end;
end;

procedure TReader.SetMaxBuffer(const Value: Cardinal);
begin
  Lock;
  try
    FMaxBuffer:=Value;
  finally
    Unlock;
  end;
end;

end.
