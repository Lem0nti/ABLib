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
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); reintroduce;
    destructor Destroy; override;
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


end.
