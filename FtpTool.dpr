program FtpTool;

uses
  Forms,
  U_FtpTool in 'U_FtpTool.pas' {Form1},
  U_ModalDialog in 'U_ModalDialog.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
