unit JsonSchema.CodeGenerator;

interface

uses
  System.Classes, JsonSchema.Reader, System.JSON.Writers, JsonSchema.Types, SynMustache,
  System.Generics.Collections, System.Types;

type
  TTypeCategory = (tcNone, tcNull, tcPrimitive, tcVariant, tcObject, tcList, tcObjectList);
  TTypeCategories = Set of TTypeCategory;

  TDelphiTypeInfo = record
    Category: TTypeCategory;
    Typename: String;
    DefaultValue: String;
    TypeFormat: String;
    function IsPrimitive: Boolean;
    procedure DeclarePrimitive(const ATypename, ADefault: String);
    procedure DeclareVariant;
    procedure Reset;
  end;

  TDelphiUnitInfo = record
    NameOfClass: String;
    NameOfUnit: String;
    Filename: String;
  end;

  TUnitInfoDynArray = Array of TDelphiUnitInfo;

  TUnitInfoDynArrayHelper = record helper for TUnitInfoDynArray
    function Filenames(const Delimiter: String = ' '): String;
  end;

  TClassMember = record
    PropertyName: String;
    FieldName: String;
    Description: String;
    TypeInfo: TDelphiTypeInfo;
  end;

  TDelphiClassModel = class(TObject)
  strict private
    FJsonSchema: TJsonSchema;
    FUnits: TStringList;
    FNameOfUnit: String;
    FNameOfClass: String;
    FMembers: TDictionary<String, TClassMember>;
  public
    constructor Create(ASchema: TJsonSchema);
    destructor Destroy; override;
    property JsonSchema: TJsonSchema read FJsonSchema;
    property NameOfClass: String read FNameOfClass write FNameOfClass;
    property NameOfUnit: String read FNameOfUnit write FNameOfUnit;
    property Members: TDictionary<String, TClassMember> read FMembers;
    property Units: TStringList read FUnits;
  end;

  TDelphiFormatter = class(TObject)
  private
    FKeywords: TStringList;
  protected
    procedure InitKeywords; virtual;
  public
    const
      KEYWORDS_CSV = 'and,array,as,asm,begin,case,class,const,constructor,destructor,dispinterface,div,do,downto,else,end,'+
      'except,exports,file,finalization,finally,for,function,goto,if,implementation,in,inherited,initialization,inline,'+
      'interface,is,label,library,mod,nil,not,object,of,or,packed,procedure,program,property,raise,record,repeat,'+
      'resourcestring,set,shl,shr,string,then,threadvar,to,try,type,unit,until,uses,var,while,with,xor';
    constructor Create;
    destructor Destroy; override;
    function AsIdentifier(const S: String): String;
  end;

  TJsonContextWriter = class(TJsonTextWriter)
  public
    procedure WriteProperty(const AName, AValue: String); overload;
    procedure WriteProperty(const AName: String; const AValue: Boolean); overload;
    procedure WriteValue(const Value: string); override;
  end;

  TCodeGeneratorSettings = class(TObject)
  strict private
    FTypeMappings: Array[TSimpleType] of String;
    FListItemClassSuffix: String;
  strict protected
    function GetBooleanType: String;
    function GetIntegerType: String;
    function GetNumberType: String;
    function GetStringType: String;
  public
    constructor Create;
    function GetTypeMapping(const st: TSimpleType): String;
    procedure SetTypeMapping(const st: TSimpleType; const TypeName: String);
    { Properties }
    property ListItemClassSuffix: String read FListItemClassSuffix write FListItemClassSuffix;
    property BooleanType: String read GetBooleanType;
    property IntegerType: String read GetIntegerType;
    property NumberType: String read GetNumberType;
    property StringType: String read GetStringType;
  end;

  TJsonSchemaCodeGenerator = class(TObject)
  strict private
    FRootSchema: TJsonSchema;
    FClassMustache: TSynMustache;
    FDelphiFmt: TDelphiFormatter;
    FTemplateFiles: TStringDynArray;
    FOutputDir: String;
    FUnitStack: TStack<TDelphiClassModel>;
    FCodeGenSettings: TCodeGeneratorSettings;
  protected
    function FindReference(const AReference: String): TJsonSchema;
    function TryFindSchemaType(AJsonSchema: TJsonSchema; out SchemaTypeInfo: TDelphiTypeInfo): Boolean;
    function GenerateSchemaClass(AJsonSchema: TJsonSchema;
      const AFilenameTemplate: String; ASchemaName: String = ''): TDelphiUnitInfo;
    function GetSchemaType(ASchema: TJsonSchema; const ASchemaName: String): TDelphiTypeInfo;
    procedure AddUnit(const UnitName: String);
    procedure SetOutputDir(const Value: String);
    procedure SetDelphiFormatter(const Value: TDelphiFormatter);
    procedure WriteClassMembers(AWriter: TJsonContextWriter; AClassInfo: TDelphiClassModel);
    procedure WriteSchemaProperties(AWriter: TJsonContextWriter; AProperties: TObjectList<TJsonSchema>);
    procedure WriteSchemaProperty(AWriter: TJsonContextWriter; ASchema: TJsonSchema);
  public
    constructor Create(ARootSchema: TJsonSchema; const ATemplateDir: String);
    destructor Destroy; override;
    class function Execute(const AFilename, ATemplateDir: String; const AOutputDir: String = ''): TUnitInfoDynArray;
    function Generate: TUnitInfoDynArray;
    procedure ReadSettings(const AFilename: String);
    { Properties }
    property DelphiFormatter: TDelphiFormatter read FDelphiFmt write SetDelphiFormatter;
    property OutputDir: String read FOutputDir write SetOutputDir;
  end;


implementation

uses
  System.SysUtils, SynCommons, System.IOUtils, System.StrUtils,
  System.RegularExpressions, System.IniFiles;

const
  JSON_SCHEMA_CODE_INIFILE = 'json-schema-code.ini';

{ TJsonSchemaCodeGenerator }

procedure TJsonSchemaCodeGenerator.AddUnit(const UnitName: String);
begin
  if FUnitStack.Count > 0 then
  begin
    FUnitStack.Peek.Units.Add(UnitName);
  end;
end;

constructor TJsonSchemaCodeGenerator.Create(ARootSchema: TJsonSchema; const ATemplateDir: String);
begin
  FRootSchema := ARootSchema;
  FDelphiFmt := TDelphiFormatter.Create;
  FUnitStack := TStack<TDelphiClassModel>.Create;
  FCodeGenSettings := TCodeGeneratorSettings.Create;

  FTemplateFiles := TDirectory.GetFiles(ATemplateDir, '{*}.pas');
  if Length(FTemplateFiles) = 0 then
    raise JsonSchemaException.CreateFmt('No template files found in %s', [ATemplateDir]);

  ReadSettings(IncludeTrailingPathDelimiter(ATemplateDir) + JSON_SCHEMA_CODE_INIFILE);
end;

destructor TJsonSchemaCodeGenerator.Destroy;
begin
  FDelphiFmt.Free;
  FUnitStack.Free;
  FCodeGenSettings.Free;
  inherited Destroy;
end;

class function TJsonSchemaCodeGenerator.Execute(const AFilename, ATemplateDir, AOutputDir: String): TUnitInfoDynArray;
var
  schemaReader: TJsonSchemaReader;
  codeGen: TJsonSchemaCodeGenerator;
begin
  if not FileExists(AFilename) then
    raise Exception.CreateFmt('File not found: %s', [AFilename]);

  schemaReader := TJsonSchemaReader.Create;
  try
    schemaReader.ReadFromFile(AFilename);
    codeGen := TJsonSchemaCodeGenerator.Create(schemaReader.JsonSchema, ATemplateDir);
    try
      if AOutputDir <> '' then
        codeGen.OutputDir := AOutputDir
      else
        codeGen.OutputDir := ExtractFilePath(AFilename) + ChangeFileExt(ExtractFileName(AFilename), '');
      ForceDirectories(codeGen.OutputDir);

      Result := codeGen.Generate;
    finally
      codeGen.Free;
    end;
  finally
    schemaReader.Free;
  end;
end;

function TJsonSchemaCodeGenerator.FindReference(const AReference: String): TJsonSchema;
var
  refSplits: TArray<String>;
  index, refDepth: Integer;
  schema, subschema: TJsonSchema;
  ref: String;
begin
  Result := nil;
  refSplits := AReference.Split(['/']);
  refDepth := Length(refSplits);
  schema := nil;
  for index := 0 to refDepth-1 do
  begin
    ref := refSplits[index];
    if (ref = '#') then
    begin
      schema := FRootSchema;
    end
    else if (schema <> nil) then
    begin
      for subschema in schema.Subschemas do
      begin
        if subschema.Name = ref then
        begin
          schema := subschema;
          break;
        end;
      end;
    end;
    if (index = refDepth - 1) then
      Result := schema;
  end;
end;

function TJsonSchemaCodeGenerator.Generate: TUnitInfoDynArray;
var
  templateFilename: String;
  templateString: String;
  index: Integer;
  lenFiles: Integer;
begin
  if FRootSchema.Name = '' then
    raise JsonSchemaException.Create('No name is specified for root schema!');

  lenFiles := Length(FTemplateFiles);
  SetLength(Result, lenFiles);
  for index := 0 to lenFiles-1 do
  begin
    templateString := TFile.ReadAllText(FTemplateFiles[index]);
    templateFilename := ExtractFileName(FTemplateFiles[index]);
    templateFilename := TRegEx.Replace(templateFilename, '^{([^{].*[^}])}\.', '$1.');
    FClassMustache := TSynMustache.Parse(RawUTF8(templateString));
    Result[index] := GenerateSchemaClass(FRootSchema, templateFilename);
    Writeln(Result[index].Filename + ' written');
  end;
  Writeln(Format('%d files was written.', [lenFiles]));
end;

function TJsonSchemaCodeGenerator.GenerateSchemaClass(AJsonSchema: TJsonSchema;
  const AFilenameTemplate: String;
  ASchemaName: String): TDelphiUnitInfo;
var
  jsonWriter: TJsonContextWriter;
  renderedOutput: RawUTF8;
  mustacheJsonContext: string;
  renderedFilename: RawUTF8;
  strWriter: TStringWriter;
  schemaClassModel: TDelphiClassModel;
begin
  strWriter := TStringWriter.Create;
  jsonWriter := TJsonContextWriter.Create(strWriter);
  schemaClassModel := TDelphiClassModel.Create(AJsonSchema);
  try
    if (ASchemaName = '') then
      ASchemaName := AJsonSchema.Name;

    schemaClassModel.NameOfUnit := FDelphiFmt.AsIdentifier(ASchemaName);
    schemaClassModel.NameOfClass := 'T' + FDelphiFmt.AsIdentifier(ASchemaName);

    if (FUnitStack.Count > 0) then
    begin
      FUnitStack.Peek.Units.Add(schemaClassModel.NameOfUnit);
    end;
    FUnitStack.Push(schemaClassModel);

    jsonWriter.WriteStartObject;
    { schema }
    jsonWriter.WritePropertyName('json-schema');
    jsonWriter.WriteStartObject;
    jsonWriter.WriteProperty('id', AJsonSchema.Id);
    jsonWriter.WriteProperty('name', AJsonSchema.Name);
    jsonWriter.WriteProperty('title', AJsonSchema.Title);
    jsonWriter.WriteProperty('description', AJsonSchema.Description);
    WriteSchemaProperties(jsonWriter, AJsonSchema.Properties);
    jsonWriter.WriteEndObject;

    { class }
    WriteClassMembers(jsonWriter, schemaClassModel);

    jsonWriter.WriteEndObject;

    mustacheJsonContext := strWriter.ToString;
    renderedOutput := FClassMustache.RenderJSON(RawUTF8(mustacheJsonContext));
    TSynMustache.TryRenderJson(RawUTF8(AFilenameTemplate), RawUTF8(mustacheJsonContext), renderedFilename);

    Result.Filename := FOutputDir + String(renderedFilename);
    Result.NameOfUnit := schemaClassModel.NameOfUnit;
    Result.NameOfClass := schemaClassModel.NameOfClass;
    FUnitStack.Pop;

    TFile.WriteAllText(Result.Filename, String(renderedOutput));
  finally
    schemaClassModel.Free;
    jsonWriter.Free;
    strWriter.Free;
  end;
end;

function TJsonSchemaCodeGenerator.GetSchemaType(ASchema: TJsonSchema; const ASchemaName: String): TDelphiTypeInfo;
var
  refSchema: TJsonSchema;
  itemType: TDelphiTypeInfo;
begin
  if TryFindSchemaType(ASchema, Result) then
    Exit;

  Result.Reset;
  case Length(ASchema.Types) of
    0:
    begin
      if (ASchema.Ref <> '') then
      begin
        refSchema := FindReference(ASchema.Ref);
        if (refSchema <> nil) then
          Result := GetSchemaType(refSchema, ASchemaName)
        else
          raise JsonSchemaException.CreateFmt('Type of property %s is unknown: %s', [ASchema.Name, ASchema.Path]);
      end
      else Result.DeclareVariant;
    end;
    1:
    begin
      case ASchema.Types[0] of
        stNone:
        begin
          Result.Category := tcNone;
          Result.Typename := '?';
        end;
        stObject:
        begin
          Result.Category := tcObject;
          Result.Typename := GenerateSchemaClass(ASchema, '{{class.unit}}.pas', ASchemaName).NameOfClass;
          Result.DefaultValue := 'nil';
        end;
        stArray:
        begin
          if (ASchema.Items.Count = 1) then
            itemType := GetSchemaType(ASchema.Items[0], ASchema.Name + FCodeGenSettings.ListItemClassSuffix)
          else
            itemType.DeclarePrimitive('String', #39#39);

          if itemType.IsPrimitive then
          begin
            Result.Category := tcList;
            Result.Typename := Format('TList<%s>', [itemType.Typename])
          end
          else begin
            Result.Category := tcObjectList;
            Result.Typename := Format('TObjectList<%s>', [itemType.Typename]);
          end;
        end;
        stNull:
        begin
          Result.Category := tcNull;
        end;
        stBoolean:
        begin
          Result.DeclarePrimitive(FCodeGenSettings.BooleanType, 'false');
          if (ASchema.DefaultValue <> nil) and ASchema.DefaultValue.IsAssigned then
            Result.DefaultValue := ASchema.DefaultValue.AsString;
        end;
        stInteger:
        begin
          Result.DeclarePrimitive(FCodeGenSettings.IntegerType, '0');
          if (ASchema.DefaultValue <> nil) and ASchema.DefaultValue.IsAssigned then
            Result.DefaultValue := ASchema.DefaultValue.AsString;
        end;
        stNumber:
        begin
          Result.DeclarePrimitive(FCodeGenSettings.NumberType, '0');
          if (ASchema.DefaultValue <> nil) and ASchema.DefaultValue.IsAssigned then
            Result.DefaultValue := ASchema.DefaultValue.AsString;
        end;
        stString:
        begin
          Result.DeclarePrimitive(FCodeGenSettings.StringType, #39#39); // ''
          Result.TypeFormat := ASchema.Format;
          if (ASchema.DefaultValue <> nil) and ASchema.DefaultValue.IsAssigned then
          begin
            Result.DefaultValue := #39 + ASchema.DefaultValue.AsString.Replace(#39, #39#39) + #39;
          end;
        end;
      else
        raise JsonSchemaException.CreateFmt('Type of %s is not supported!', [ASchema.Path]);
      end;
    end;
    else begin
      Result.DeclareVariant;
    end;
  end;
end;

procedure TJsonSchemaCodeGenerator.ReadSettings(const AFilename: String);
var
  ini: TMemIniFile;
begin
  if FileExists(AFilename) then
  begin
    ini := TMemIniFile.Create(AFilename);
    try
      FCodeGenSettings.ListItemClassSuffix := ini.ReadString('General', 'ListItemClassSuffix', 'Item');
      FCodeGenSettings.SetTypeMapping(stBoolean, ini.ReadString('SimpleTypes', 'boolean', 'Boolean'));
      FCodeGenSettings.SetTypeMapping(stInteger, ini.ReadString('SimpleTypes', 'integer', 'Integer'));
      FCodeGenSettings.SetTypeMapping(stNumber, ini.ReadString('SimpleTypes', 'number', 'Double'));
      FCodeGenSettings.SetTypeMapping(stString, ini.ReadString('SimpleTypes', 'string', 'String'));
    finally
      ini.Free;
    end;
  end;
end;

procedure TJsonSchemaCodeGenerator.SetDelphiFormatter(const Value: TDelphiFormatter);
begin
  FDelphiFmt.Free;
  FDelphiFmt := Value;
end;

procedure TJsonSchemaCodeGenerator.SetOutputDir(const Value: String);
begin
  FOutputDir := IncludeTrailingPathDelimiter(Value);
end;

function TJsonSchemaCodeGenerator.TryFindSchemaType(
  AJsonSchema: TJsonSchema; out SchemaTypeInfo: TDelphiTypeInfo): Boolean;
var
  dcm: TDelphiClassModel;
begin
  for dcm in FUnitStack do
  begin
    if dcm.JsonSchema = AJsonSchema then
    begin
      SchemaTypeInfo.Category := tcObject;
      SchemaTypeInfo.Typename := dcm.NameOfClass;
      SchemaTypeInfo.DefaultValue := 'nil';
      SchemaTypeInfo.TypeFormat := '';
      Result := true;
      Exit;
    end;
  end;
  Result := false;
end;

procedure TJsonSchemaCodeGenerator.WriteSchemaProperties(AWriter: TJsonContextWriter; AProperties: TObjectList<TJsonSchema>);
var
  prop: TJsonSchema;
begin
  AWriter.WritePropertyName('properties');
  AWriter.WriteStartArray;
  for prop in AProperties do
  begin
    AWriter.WriteStartObject;
    WriteSchemaProperty(AWriter, prop);
    AWriter.WriteEndObject;
  end;
  AWriter.WriteEndArray;
end;

procedure TJsonSchemaCodeGenerator.WriteSchemaProperty(AWriter: TJsonContextWriter; ASchema: TJsonSchema);
var
  propInfo: TClassMember;
begin
  propInfo.TypeInfo := GetSchemaType(ASchema, '');
  propInfo.PropertyName := FDelphiFmt.AsIdentifier(ASchema.Name);
  propInfo.FieldName := 'F' + propInfo.PropertyName;
  propInfo.Description := ASchema.Description;

  AWriter.WriteProperty('property', propInfo.PropertyName);
  AWriter.WriteProperty('field', propInfo.FieldName);
  AWriter.WriteProperty('type', propInfo.TypeInfo.Typename);
  AWriter.WriteProperty('description', ASchema.Description);

  if (FUnitStack.Count > 0) then
  begin
    FUnitStack.Peek.Members.Add(ASchema.Name, propInfo);
  end;
end;

procedure TJsonSchemaCodeGenerator.WriteClassMembers(AWriter: TJsonContextWriter; AClassInfo: TDelphiClassModel);

  procedure WriteProperties(const AName: String; const ACategories: TTypeCategories; AMembers: TDictionary<String, TClassMember>);
  var
    schemaName: String;
    memberInfo: TClassMember;
    typeSplits: TArray<String>;
    required: Boolean;
  begin
    if (AMembers.Count > 0) then
    begin
      AWriter.WritePropertyName(AName);
      AWriter.WriteStartArray;
      for schemaName in AMembers.Keys do
      begin
        memberInfo := AMembers.Items[schemaName];
        if memberInfo.TypeInfo.Category in ACategories then
        begin
          AWriter.WriteStartObject;
          AWriter.WriteProperty('json_property', schemaName);
          AWriter.WriteProperty('property', memberInfo.PropertyName);
          AWriter.WriteProperty('field', memberInfo.FieldName);
          AWriter.WriteProperty('type', memberInfo.TypeInfo.Typename);
          AWriter.WriteProperty('format', memberInfo.TypeInfo.TypeFormat);
          AWriter.WriteProperty(memberInfo.TypeInfo.TypeFormat, true);
          AWriter.WriteProperty('default', memberInfo.TypeInfo.DefaultValue);
          AWriter.WriteProperty('comment', memberInfo.Description);
          required := AClassInfo.JsonSchema.Required.IndexOf(schemaName) >= 0;
          AWriter.WriteProperty('required', required);
          if memberInfo.TypeInfo.Category in [tcList, tcObjectList] then
          begin
            typeSplits := memberInfo.TypeInfo.TypeName.Split(['<', '>']);
            if Length(typeSplits) = 2 then
            begin
              AWriter.WriteProperty('itemtype', typeSplits[1]);
            end;
          end;
          AWriter.WriteEndObject;
        end;
      end;
      AWriter.WriteEndArray;
    end;
  end;

var
  index: integer;
begin
  AWriter.WritePropertyName('class');
  AWriter.WriteStartObject;
  AWriter.WriteProperty('name', AClassInfo.NameOfClass);
  AWriter.WriteProperty('unit', AClassInfo.NameOfUnit);
  if AClassInfo.Units.Count > 0 then
  begin
    AWriter.WritePropertyName('units');
    AWriter.WriteStartArray;
    for index:=0 to AClassInfo.Units.Count-1 do
    begin
      AWriter.WriteStartObject;
      AWriter.WriteProperty('name', AClassInfo.Units[index]);
      AWriter.WriteProperty('separator', IfThen(index < AClassInfo.Units.Count-1, ',', ';'));
      AWriter.WriteEndObject;
    end;
    AWriter.WriteEndArray;
  end;
  WriteProperties('primitives', [tcPrimitive], AClassInfo.Members);
  WriteProperties('variants', [tcVariant], AClassInfo.Members);
  WriteProperties('lists', [tcList], AClassInfo.Members);
  WriteProperties('objects', [tcObject], AClassInfo.Members);
  WriteProperties('objectlists', [tcObjectList], AClassInfo.Members);
  WriteProperties('allobjects', [tcObject, tcList, tcObjectList], AClassInfo.Members);
  WriteProperties('properties', [tcPrimitive, tcVariant, tcObject, tcList, tcObjectList], AClassInfo.Members);
  AWriter.WriteEndObject;
end;

{ TDelphiFormatter }

function TDelphiFormatter.AsIdentifier(const S: String): String;
const
  IDENTIFIER_FIRST_CHARS = ['_', 'a'..'z', 'A'..'Z'];
  IDENTIFIER_CHARS = IDENTIFIER_FIRST_CHARS + ['0'..'9'];
var
  i: Integer;
begin
  if (S.Length > 0) then
  begin
    // Delphi Keyword check
    if FKeywords.IndexOf(S) >= 0 then
    begin
      Result := '_' + UpCase(S[1]) + S.Substring(1);
    end
    else begin
      if not CharInSet(S[1], IDENTIFIER_FIRST_CHARS) then
        Result := '_' + S
      else
        Result := UpCase(S[1]) + S.Substring(1);

      for i:=1 to Result.Length-1 do
      begin
        if not CharInSet(Result[i], IDENTIFIER_CHARS) then
          Result[i] := '_';
      end;
    end;
  end
  else begin
    Result := '';
  end;
end;

constructor TDelphiFormatter.Create;
begin
  InitKeywords;
end;

destructor TDelphiFormatter.Destroy;
begin
  FKeywords.Free;
  inherited;
end;

procedure TDelphiFormatter.InitKeywords;
var
  keywords: TArray<String>;
  index: integer;
begin
  FKeywords := TStringList.Create;
  FKeywords.CaseSensitive := false;
  FKeywords.Duplicates := dupIgnore;
  FKeywords.Sorted := true;

  keywords := KEYWORDS_CSV.Split([',']);
  for index := 0 to Length(keywords)-1 do
  begin
    FKeywords.Add(keywords[index]);
  end;
end;

{ TJsonContextWriter }

procedure TJsonContextWriter.WriteProperty(const AName, AValue: String);
begin
  if (AValue <> '') then
  begin
    WritePropertyName(AName);
    WriteValue(AValue);
  end;
end;

procedure TJsonContextWriter.WriteProperty(const AName: String; const AValue: Boolean);
begin
  WritePropertyName(AName);
  WriteValue(AValue);
end;

procedure TJsonContextWriter.WriteValue(const Value: string);

  function RemoveControlChars(const S: String): String;
  var
    i, j: Integer;
  begin
    SetLength(Result, Length(S));
    j := 0;
    for i:=1 to Length(S) do
    begin
      if not CharInSet(S[i], [#$00..#$1F, #$7F]) then
      begin
        inc(j);
        Result[j] := S[i];
      end;
    end;
    SetLength(Result, j);
  end;

begin
  inherited WriteValue(RemoveControlChars(Value));
end;

{ TDelphiClassModel }

constructor TDelphiClassModel.Create(ASchema: TJsonSchema);
begin
  FJsonSchema := ASchema;
  FMembers := TDictionary<String,TClassMember>.Create;
  FUnits := TStringList.Create;
  FUnits.Duplicates := dupIgnore;
  FUnits.Sorted := true;
end;

destructor TDelphiClassModel.Destroy;
begin
  FMembers.Free;
  FUnits.Free;
  inherited Destroy;
end;

{ TDelphiTypeInfo }

procedure TDelphiTypeInfo.DeclarePrimitive(const ATypename, ADefault: String);
begin
  Self.Category := tcPrimitive;
  Self.Typename := ATypename;
  Self.DefaultValue := ADefault;
end;


procedure TDelphiTypeInfo.DeclareVariant;
begin
  self.Category := tcVariant;
  self.Typename := 'Variant';
  self.DefaultValue := 'Null';
end;

function TDelphiTypeInfo.IsPrimitive: Boolean;
begin
  Result := Category = tcPrimitive;
end;

procedure TDelphiTypeInfo.Reset;
begin
  Category := tcNone;
  Typename := '';
  TypeFormat := '';
  DefaultValue := '';
end;

{ TCodeGeneratorSettings }

constructor TCodeGeneratorSettings.Create;
begin
  FListItemClassSuffix := 'Item';
  FTypeMappings[stNone] := '';
  FTypeMappings[stArray] := '';
  FTypeMappings[stBoolean] := 'Boolean';
  FTypeMappings[stInteger] := 'Integer';
  FTypeMappings[stNull] := '';
  FTypeMappings[stNumber] := 'Double';
  FTypeMappings[stObject] := '';
  FTypeMappings[stString] := 'String';
end;

function TCodeGeneratorSettings.GetBooleanType: String;
begin
  Result := FTypeMappings[stBoolean];
end;

function TCodeGeneratorSettings.GetIntegerType: String;
begin
  Result := FTypeMappings[stInteger];
end;

function TCodeGeneratorSettings.GetNumberType: String;
begin
  Result := FTypeMappings[stNumber];
end;

function TCodeGeneratorSettings.GetStringType: String;
begin
  Result := FTypeMappings[stString];
end;

function TCodeGeneratorSettings.GetTypeMapping(const st: TSimpleType): String;
begin
  Result := FTypeMappings[st];
end;

procedure TCodeGeneratorSettings.SetTypeMapping(const st: TSimpleType; const TypeName: String);
begin
  FTypeMappings[st] := TypeName;
end;

{ TUnitInfoDynArrayHelper }

function TUnitInfoDynArrayHelper.Filenames(const Delimiter: String): String;
var
  index: Integer;
begin
  Result := '';
  for index := 0 to Length(Self)-1 do
  begin
    if (index > 0) then
      Result := Result + Delimiter;
    Result := Result + self[index].Filename;
  end;
end;

end.
