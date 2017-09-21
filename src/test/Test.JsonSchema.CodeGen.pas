unit Test.JsonSchema.CodeGen;

interface

uses
  DUnitX.TestFramework, System.Classes, JsonSchema.Reader;

type
  TestJsonSchemaCodeGenerator = class(TObject)
  protected
    procedure Compile(const AFilename: String);
  public
    [Test]
    procedure CompileGeneratedCode;
    [Test]
    procedure CompileSampleJsonSchema;
  end;

implementation

uses
  JsonSchema.CodeGenerator, dcc32utils, Test.Consts;

{ TestJsonSchemaCodeGenerator }

procedure TestJsonSchemaCodeGenerator.Compile(const AFilename: String);
var
  params: String;
  exitCode: cardinal;
  output: TStringList;
begin
  output := TStringList.Create;
  try
    params := AFilename;
    exitCode := DCC32.Compile(params, output);
    if exitCode <> 0 then
    begin
      System.Writeln(output.Text);
    end;
    Assert.AreEqual(0, exitCode);
  finally
    output.Free;
  end;
end;

procedure TestJsonSchemaCodeGenerator.CompileGeneratedCode;
var
  unitInfos: TUnitInfoDynArray;
  templateDir: String;
begin
  templateDir := TEST_TEMPLATES_DIR;

  unitInfos := TJsonSchemaCodeGenerator.Execute(TEST_RESOURCES_DIR + '\draft-04-schema.json', templateDir);
  Compile(unitInfos.Filenames);

  unitInfos := TJsonSchemaCodeGenerator.Execute(TEST_RESOURCES_DIR + '\valid\chrome-manifest.json', templateDir);
  Compile(unitInfos.Filenames);

  unitInfos := TJsonSchemaCodeGenerator.Execute(TEST_RESOURCES_DIR + '\valid\resume.json', templateDir);
  Compile(unitInfos.Filenames);
end;

procedure TestJsonSchemaCodeGenerator.CompileSampleJsonSchema;
var
  codeGen: TJsonSchemaCodeGenerator;
  schemaReader: TJsonSchemaReader;
begin
  schemaReader := TJsonSchemaReader.Create;
  try
    schemaReader.ReadFromString('{'+
      '"description": "JSON Schema \n with line break",'+
      '"type": "object",'+
      '"properties": {'+
      '}'+
    '}');
    schemaReader.JsonSchema.Name := 'LineBreakSample';
    codeGen := TJsonSchemaCodeGenerator.Create(schemaReader.JsonSchema, TEST_TEMPLATES_DIR);
    Compile(codeGen.Generate.Filenames);
  finally
    schemaReader.Free;
  end;
end;

initialization

  TDUnitX.RegisterTestFixture(TestJsonSchemaCodeGenerator);

end.
