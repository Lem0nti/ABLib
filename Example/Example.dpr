program Example;

uses
  Vcl.Forms,
  eMain_FM in 'eMain_FM.pas' {MainFM},
  eDirect_Cl in 'eDirect_Cl.pas',
  eMessage in 'eMessage.pas',
  eTimer_Cl in 'eTimer_Cl.pas',
  eTCPToLog_Cl in 'eTCPToLog_Cl.pas',
  ABL.IA.FindDark in '..\ABL.IA.FindDark.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainFM, MainFM);
  Application.Run;
end.
