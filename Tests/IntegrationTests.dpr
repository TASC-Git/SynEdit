program IntegrationTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Vcl.Forms,
  TestFramework,
  TextTestRunner,
  UpstreamIntegrationTests in 'UpstreamIntegrationTests.pas';

var
  Results: TTestResult;
begin
  Application.Initialize;
  Results := TextTestRunner.RunRegisteredTests(rxbContinue);
  try
    if not Results.WasSuccessful then
      ExitCode := 1;
  finally
    Results.Free;
  end;
end.
