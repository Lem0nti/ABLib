unit ABL.IA.Opening;

interface

uses
  ABL.Core.BaseObject, ABL.Core.BaseQueue, ABL.IA.Erosion, ABL.IA.Dilation, ABL.Core.ThreadQueue, SysUtils;

type
  TOpening=class(TBaseObject)
  private
    Erosion: TErosion;
    Dilation: TDilation;
    ThreadQueue: TThreadQueue;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); reintroduce;
    destructor Destroy; override;
    function InputQueue: TBaseQueue;
    function OutputQueue: TBaseQueue;
    procedure SetInputQueue(Queue: TBaseQueue);
    procedure SetOutputQueue(Queue: TBaseQueue);
  end;

implementation

{ TOpening }

constructor TOpening.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AName);
  ThreadQueue:=TThreadQueue.Create('TClosing_'+AName+'_ED_'+IntToStr(FID));
  Erosion:=TErosion.Create(AInputQueue,ThreadQueue,'TClosing_'+AName+'_Erosion_'+IntToStr(FID));
  Erosion.Parent:=Self;
  Dilation:=TDilation.Create(ThreadQueue,AOutputQueue,'TClosing_'+AName+'_Dilation_'+IntToStr(FID));
  Dilation.Parent:=Self;
end;

destructor TOpening.Destroy;
begin
  Erosion.Parent:=nil;
  Erosion.Free;
  Dilation.Parent:=nil;
  Dilation.Free;
  ThreadQueue.Free;
  inherited;
end;


function TOpening.InputQueue: TBaseQueue;
begin
  result:=Erosion.InputQueue;
end;

function TOpening.OutputQueue: TBaseQueue;
begin
  result:=Dilation.OutputQueue;
end;

procedure TOpening.SetInputQueue(Queue: TBaseQueue);
begin
  Erosion.SetInputQueue(Queue);
end;

procedure TOpening.SetOutputQueue(Queue: TBaseQueue);
begin
  Dilation.SetOutputQueue(Queue);
end;

end.
