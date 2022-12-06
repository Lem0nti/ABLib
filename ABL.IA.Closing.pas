unit ABL.IA.Closing;

interface

uses
  ABL.Core.BaseObject, ABL.Core.BaseQueue, ABL.IA.Erosion, ABL.IA.Dilation, ABL.Core.ThreadQueue, SysUtils;

type
  TClosing=class(TBaseObject)
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

{ TClosing }

constructor TClosing.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AName);
  ThreadQueue:=TThreadQueue.Create('TClosing_'+AName+'_DE_'+IntToStr(FID));
  Dilation:=TDilation.Create(AInputQueue,ThreadQueue,'TClosing_'+AName+'_Dilation_'+IntToStr(FID));
  Dilation.Parent:=Self;
  Erosion:=TErosion.Create(ThreadQueue,AOutputQueue,'TClosing_'+AName+'_Erosion_'+IntToStr(FID));
  Erosion.Parent:=Self;
end;

destructor TClosing.Destroy;
begin
  Dilation.Parent:=nil;
  Dilation.Free;
  Erosion.Parent:=nil;
  Erosion.Free;
  ThreadQueue.Free;
  inherited;
end;


end.
