unit UpstreamIntegrationTests;

interface

uses
  System.Classes, System.SysUtils, Vcl.Forms, TestFramework,
  SynEdit, SynEditTypes, SynEditTextBuffer, SynExportTeX;

type
  TExporterProbe = class(TSynExporterTeX)
  public
    procedure WriteText(const Value: string);
  end;

  TUpstreamIntegrationTests = class(TTestCase)
  private
    FForm: TForm;
    FEditor: TSynEdit;
    FBuffer: TSynEditStringList;
    FUndo: ISynEditUndo;
    FNotifications: Integer;
    procedure BinaryDetected(Sender: TObject);
    procedure HookBuffer;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure AnsiExportRoundTrip;
    procedure BinaryToExternalTextClearsBinaryMode;
    procedure ExternalBinaryActivatesBinaryMode;
    procedure UnhookRestoresOriginalBinaryMode;
    procedure UnhookRestoresOriginalTextMode;
    procedure ExternalLoadsUpdateModeAndPreserveCallback;
    procedure UnhookRestoresExternalCallback;
    procedure SharedEditorsReceiveBinaryNotifications;
    procedure DisabledDetectionPreservesManualMode;
  end;

implementation

procedure TExporterProbe.WriteText(const Value: string);
begin
  Clear;
  AddData(Value);
end;

procedure TUpstreamIntegrationTests.SetUp;
begin
  inherited;
  FNotifications := 0;
  FForm := TForm.Create(nil);
  FEditor := TSynEdit.Create(FForm);
  FEditor.Parent := FForm;
  FBuffer := TSynEditStringList.Create(nil);
  FUndo := FEditor.CreateUndoRedoManager;
end;

procedure TUpstreamIntegrationTests.TearDown;
begin
  FEditor.UnHookTextBuffer;
  FBuffer.Free;
  FUndo := nil;
  FForm.Free;
  inherited;
end;

procedure TUpstreamIntegrationTests.BinaryDetected(Sender: TObject);
begin
  Inc(FNotifications);
end;

procedure TUpstreamIntegrationTests.HookBuffer;
begin
  FEditor.HookTextBuffer(FBuffer, FUndo);
end;

procedure TUpstreamIntegrationTests.AnsiExportRoundTrip;
var
  Exporter: TExporterProbe;
  Value: string;
begin
  Exporter := TExporterProbe.Create(nil);
  try
    // Use the local ANSI encoding's representable text, including non-ASCII
    // on Western code pages. This never reads or writes the system clipboard.
    Value := TEncoding.ANSI.GetString(TEncoding.ANSI.GetBytes('caf' + #$E9));
    Exporter.WriteText(Value);
    CheckEqualsString(Value, Exporter.ExportedText);
  finally
    Exporter.Free;
  end;
end;

procedure TUpstreamIntegrationTests.BinaryToExternalTextClearsBinaryMode;
begin
  FEditor.Lines.Text := 'binary' + #0;
  CheckTrue(FEditor.BinaryMode);
  FBuffer.Text := 'SELECT 1;';
  HookBuffer;
  CheckFalse(FEditor.BinaryMode, 'Text buffer must not inherit binary display state');
end;

procedure TUpstreamIntegrationTests.ExternalBinaryActivatesBinaryMode;
begin
  FBuffer.Text := 'binary' + #0;
  HookBuffer;
  CheckTrue(FEditor.BinaryMode);
end;

procedure TUpstreamIntegrationTests.UnhookRestoresOriginalBinaryMode;
begin
  FEditor.Lines.Text := 'binary' + #0;
  HookBuffer;
  CheckFalse(FEditor.BinaryMode);
  FEditor.UnHookTextBuffer;
  CheckTrue(FEditor.BinaryMode);
end;

procedure TUpstreamIntegrationTests.UnhookRestoresOriginalTextMode;
begin
  FBuffer.Text := 'binary' + #0;
  HookBuffer;
  CheckTrue(FEditor.BinaryMode);
  FEditor.UnHookTextBuffer;
  CheckFalse(FEditor.BinaryMode);
end;

procedure TUpstreamIntegrationTests.ExternalLoadsUpdateModeAndPreserveCallback;
begin
  FBuffer.OnBinaryFile := BinaryDetected;
  HookBuffer;
  FBuffer.Text := 'binary' + #0;
  CheckTrue(FEditor.BinaryMode);
  FBuffer.Text := 'SELECT 1;';
  CheckFalse(FEditor.BinaryMode);
  CheckEquals(2, FNotifications);
end;

procedure TUpstreamIntegrationTests.UnhookRestoresExternalCallback;
begin
  FBuffer.OnBinaryFile := BinaryDetected;
  HookBuffer;
  FEditor.UnHookTextBuffer;
  FBuffer.Text := 'binary' + #0;
  CheckEquals(1, FNotifications);
  CheckFalse(FEditor.BinaryMode, 'Detached buffer must not notify the old editor');
end;

procedure TUpstreamIntegrationTests.SharedEditorsReceiveBinaryNotifications;
var
  Other: TSynEdit;
begin
  Other := TSynEdit.Create(FForm);
  try
    Other.Parent := FForm;
    Other.SetLinesPointer(FEditor);
    try
      FEditor.Lines.Text := 'binary' + #0;
      CheckTrue(FEditor.BinaryMode);
      CheckTrue(Other.BinaryMode);
      FEditor.Lines.Text := 'SELECT 1;';
      CheckFalse(FEditor.BinaryMode);
      CheckFalse(Other.BinaryMode);
    finally
      Other.RemoveLinesPointer;
    end;
    FEditor.Lines.Text := 'binary' + #0;
    CheckTrue(FEditor.BinaryMode);
    CheckFalse(Other.BinaryMode);
  finally
    Other.Free;
  end;
end;

procedure TUpstreamIntegrationTests.DisabledDetectionPreservesManualMode;
begin
  FEditor.AutoDetectBinary := False;
  FEditor.BinaryMode := True;
  HookBuffer;
  CheckTrue(FEditor.BinaryMode);
  FBuffer.Text := 'SELECT 1;';
  CheckTrue(FEditor.BinaryMode);
  FEditor.UnHookTextBuffer;
  CheckTrue(FEditor.BinaryMode);
end;

initialization
  RegisterTest(TUpstreamIntegrationTests.Suite);
end.
