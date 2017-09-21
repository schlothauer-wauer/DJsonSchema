unit TestJsonSchemaReader;

interface

uses
  DUnitX.TestFramework, System.Classes, JsonSchema.Reader;

type
  TJsonSchemaReaderTest = class(TObject)
  protected
    procedure CheckEqualJSON(const ExpectedFilename: String; ActualJsonSchema: TJsonSchema);
    procedure ReadAndWriteJsonSchema(const AJsonFilename: String);
  public
    [Test]
    procedure ReadSimpleSchema1;
    [Test]
    procedure ReadNestedSchema;
    [Test]
    [TestCase('draft-04-schema', 'draft-04-schema.json')]
    [TestCase('hyper-schema', 'hyper-schema.json')]
    procedure TestJsonSchemaReader(const AJsonFilename: String);
    [Test]
    procedure ReadValidSamples;
  end;

implementation

uses
  System.Generics.Collections, JsonSchema.Types, TestAssertUtils,
  System.IOUtils, System.SysUtils, JsonSchema.Writer, System.JSON.Writers,
  System.JSON.Types, System.Math, System.Types, DUnitX.Exceptions, Test.Consts;

function ArrayToString(const strings: TArray<String>): String;
var
  i: integer;
begin
  Result := '';
  for i:=0 to Length(strings)-1 do
  begin
    if i > 0 then
      Result := Result + ',';
    Result := Result + strings[i];
  end;
end;

function ArrayToSortedString(const strings: TArray<String>): String;
var
  i: integer;
  StringList: TStringList;
begin
  Result := '';
  StringList := TStringList.Create;
  try
    for i:=0 to Length(strings)-1 do
    begin
      StringList.Add(strings[i]);
    end;
    StringList.Sort;
    Result := StringList.CommaText;
  finally
    StringList.Free;
  end;
end;

function GetJsonSchemaObjectNames(AJsonSchemaObjects: TObjectList<TJsonSchema>): String;
var
  names: TArray<String>;
  index: Integer;
begin
  SetLength(names, AJsonSchemaObjects.Count);
  for index:=0 to AJsonSchemaObjects.Count-1 do
  begin
    names[index] := AJsonSchemaObjects[index].Name;
  end;
  Result := ArrayToSortedString(names);
end;

{ TJsonSchemaReaderTest }

procedure TJsonSchemaReaderTest.CheckEqualJSON(const ExpectedFilename: String; ActualJsonSchema: TJsonSchema);
var
  expectedStrings: TStringList;
  actualStrings: TStringList;
begin
  expectedStrings := TStringList.Create;
  expectedStrings.LoadFromFile(ExpectedFilename);
  actualStrings := TStringList.Create;
  try
    actualStrings.Text := TJsonSchemaWriter.asJSON(ActualJsonSchema);
    actualStrings.DefaultEncoding := TEncoding.UTF8;
    try
      AssertUtils.CheckEquals(expectedStrings, actualStrings, []);
    except
      on E: ETestFailure do
      begin
        actualStrings.SaveToFile(ExpectedFilename + '~');
        raise;
      end;
    end;
  finally
    actualStrings.Free;
    expectedStrings.Free;
  end;
end;

procedure TJsonSchemaReaderTest.ReadAndWriteJsonSchema(const AJsonFilename: String);
var
  schemaReader: TJsonSchemaReader;
begin
  schemaReader := TJsonSchemaReader.Create;
  try
    schemaReader.ReadFromFile(AJsonFilename);
    CheckEqualJSON(AJsonFilename, schemaReader.JsonSchema);
  finally
    schemaReader.Free;
  end;
end;

procedure TJsonSchemaReaderTest.ReadValidSamples;
var
  files: TStringDynArray;
  index: Integer;
begin
  files := TDirectory.GetFiles(TEST_RESOURCES_DIR + '\valid', '*.json');
  for index := 0 to Length(files)-1 do
  begin
    try
      ReadAndWriteJsonSchema(files[index]);
    except
      on E: Exception do
        raise ETestFailure.Create(E.Message + ': ' + files[index]);
    end;
  end;
end;

procedure TJsonSchemaReaderTest.ReadNestedSchema;
var
  reader: TJsonSchemaReader;
begin
  reader := TJsonSchemaReader.Create;
  try
    reader.ReadFromString('{'+
      '"title": "root",'+
      '"otherSchema": {'+
        '"title": "nested", '+
        '"anotherSchema": {'+
          '"title": "alsoNested"'+
      '}}}');
    Assert.AreEqual('root', reader.JsonSchema.Title);
    Assert.AreEqual(1, reader.JsonSchema.NestedSchemas.Count);
    Assert.AreEqual('nested', reader.JsonSchema.NestedSchemas[0].Title);
  finally
    reader.Free
  end;
end;

procedure TJsonSchemaReaderTest.ReadSimpleSchema1;
var
  reader: TJsonSchemaReader;
begin
  reader := TJsonSchemaReader.Create;
  try
    reader.ReadFromString('{"title": "rööt"}');
    Assert.AreEqual('rööt', reader.JsonSchema.Title);
    Assert.AreEqual(0, reader.JsonSchema.Properties.Count);
  finally
    reader.Free;
  end;
end;

procedure TJsonSchemaReaderTest.TestJsonSchemaReader(const AJsonFilename: String);
begin
  ReadAndWriteJsonSchema(TEST_RESOURCES_DIR + '\' + AJsonFilename);
end;

initialization

  TDUnitX.RegisterTestFixture(TJsonSchemaReaderTest);

end.
