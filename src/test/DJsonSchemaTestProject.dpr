program JsonSchemaTestProject;

{$WARN DUPLICATE_CTOR_DTOR OFF}

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  TestJsonSchemaReader in 'TestJsonSchemaReader.pas',
  JsonSchema.Reader in '..\JsonSchema.Reader.pas',
  JsonSchema.CodeGenerator in '..\JsonSchema.CodeGenerator.pas',
  JsonSchema.Types in '..\JsonSchema.Types.pas',
  JsonSchema.Keywords in '..\JsonSchema.Keywords.pas',
  TestAssertUtils in 'TestAssertUtils.pas',
  JsonSchema.Writer in '..\JsonSchema.Writer.pas',
  SynMustache in '..\dmustache\SynMustache.pas',
  SynCommons in '..\dmustache\SynCommons.pas',
  SynLZ in '..\dmustache\SynLZ.pas',
  Test.JsonSchema.CodeGen in 'Test.JsonSchema.CodeGen.pas',
  dcc32utils in 'dcc32utils.pas',
  Test.Consts in 'Test.Consts.pas';

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  exit;
{$ENDIF}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //tell the runner how we will log things
    //Log to the console window
    logger := TDUnitXConsoleLogger.Create(true);
    runner.AddLogger(logger);
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    runner.FailsOnNoAsserts := False; //When true, Assertions must be made during tests;

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
