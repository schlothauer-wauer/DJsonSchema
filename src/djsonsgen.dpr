program djsonsgen;

{$APPTYPE CONSOLE}

{$R *.res}

{$WARN DUPLICATE_CTOR_DTOR OFF}

uses
  System.SysUtils,
  JsonSchema.Reader in 'JsonSchema.Reader.pas',
  JsonSchema.CodeGenerator in 'JsonSchema.CodeGenerator.pas',
  SynCommons in 'dmustache\SynCommons.pas',
  SynLZ in 'dmustache\SynLZ.pas',
  SynMustache in 'dmustache\SynMustache.pas',
  GpCommandLineParser in 'GpCommandLineParser.pas';

type
  TCommandLine = class
  strict private
    FTemplateDir: string;
    FJsonSchemaFile: string;
    FOutputDir: string;
  public
    [CLPPosition(1), CLPDescription('JSON Schema file'), CLPLongName('json_schema'), CLPRequired]
    property JsonSchemaFile: string read FJsonSchemaFile write FJsonSchemaFile;

    [CLPPosition(2), CLPDescription('Template source directory', '<path>'), CLPLongName('template_dir'), CLPRequired]
    property TemplateDir: string read FTemplateDir write FTemplateDir;

    [CLPName('o'), CLPDescription('Output directory (default = use json_schema filename as directory)', '<path>'), CLPLongName('output_dir')]
    property OutputDir: string read FOutputDir write FOutputDir;
  end;

var
  cmdLine: TCommandLine;
  s: String;
begin
  cmdLine := TCommandLine.Create;
  try
    cmdLine.TemplateDir := GetCurrentDir;
    if not CommandLineParser.Parse(cmdLine) then
    begin
      for s in CommandLineParser.Usage do
        Writeln(s);
      Halt(1);
    end;

    try
      TJsonSchemaCodeGenerator.Execute(cmdLine.JsonSchemaFile, cmdLine.TemplateDir, cmdLine.OutputDir);
    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;
  finally
    cmdLine.Free;
  end;
end.
