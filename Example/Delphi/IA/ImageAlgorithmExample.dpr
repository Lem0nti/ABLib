program ImageAlgorithmExample;

uses
  Vcl.Forms,
  iaeMain_FM in 'iaeMain_FM.pas' {MinFM};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMinFM, MinFM);
  Application.Run;
end.
