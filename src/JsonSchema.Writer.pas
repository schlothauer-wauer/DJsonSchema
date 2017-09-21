unit JsonSchema.Writer;

interface

uses
  System.SysUtils, System.JSON.Writers, JsonSchema.Reader, System.Classes,
  System.Generics.Collections, System.JSON.Types, JsonSchema.Keywords;

type
  TJsonSchemaWriter = class(TObject)
  private
    FJsonWriter: TJsonTextWriter;
  protected
    procedure WriteAnyType(const AValue: TJsonVariant);
    procedure WriteAnyTypeProperty(const AProperty: TJsonSchemaProperty; const AValue: TJsonVariant);
    procedure WriteArray(const AProperty: TJsonSchemaProperty; AVariants: TObjectList<TJsonVariant>);
    procedure WriteDependencies(ADependencies: TObjectList<TJsonDependency>);
    procedure WriteStringArray(const AProperty: String; AStrings: TStrings);
    procedure WriteSchemaArray(const AProperty: TJsonSchemaProperty; AJsonSchemaList: TObjectList<TJsonSchema>);
    procedure WriteSchemaObjects(const AProperty: TJsonSchemaProperty; AJsonSchemaList: TObjectList<TJsonSchema>);
    procedure WriteSchemaList(AJsonSchemaList: TObjectList<TJsonSchema>);
    procedure WriteTypes(AJsonSchema: TJsonSchema);
  public
    constructor Create(AJsonTextWriter: TJsonTextWriter);
    destructor Destroy; override;
    class function asJSON(AJsonSchema: TJsonSchema): String;
    procedure WriteJsonSchema(AJsonSchema: TJsonSchema);
  end;


implementation

uses
  JsonSchema.Types, System.Math;

{ TJsonSchemaWriter }

class function TJsonSchemaWriter.asJSON(AJsonSchema: TJsonSchema): String;
var
  strBuilder: TStringBuilder;
  strWriter: TStringWriter;
  jsonWriter: TJsonTextWriter;
  schemaWriter: TJsonSchemaWriter;
begin
  strBuilder := TStringBuilder.Create;
  strWriter:= TStringWriter.Create(strBuilder);
  jsonWriter := TJsonTextWriter.Create(strWriter);
  jsonWriter.Formatting := TJsonFormatting.Indented;
  schemaWriter := TJsonSchemaWriter.Create(jsonWriter);
  try
    schemaWriter.WriteJsonSchema(AJsonSchema);
    Result := strBuilder.ToString;
  finally
    schemaWriter.Free;
    jsonWriter.Free;
    strWriter.Free;
    strBuilder.Free;
  end;
end;

constructor TJsonSchemaWriter.Create(AJsonTextWriter: TJsonTextWriter);
begin
  inherited Create;
  FJsonWriter := AJsonTextWriter;
end;

destructor TJsonSchemaWriter.Destroy;
begin
  inherited;
end;

procedure TJsonSchemaWriter.WriteAnyType(const AValue: TJsonVariant);
begin
  case AValue.ValueType of
    stArray: ;
    stBoolean: FJsonWriter.WriteValue(AValue.AsBoolean);
    stInteger: FJsonWriter.WriteValue(AValue.AsInteger);
    stNumber: FJsonWriter.WriteValue(AValue.AsNumber);
    stObject: WriteJsonSchema(AValue.Schema);
    stString: FJsonWriter.WriteValue(AValue.AsString);
    stNull: FJsonWriter.WriteNull;
  end;
end;

procedure TJsonSchemaWriter.WriteAnyTypeProperty(const AProperty: TJsonSchemaProperty; const AValue: TJsonVariant);
begin
  if AValue.ValueType = stArray then
  begin
    WriteArray(AProperty, AValue.VariantArray);
  end
  else if (AValue.ValueType <> stNone) then
  begin
    FJsonWriter.WritePropertyName(AProperty.ToString);
    WriteAnyType(AValue);
  end;
end;

procedure TJsonSchemaWriter.WriteArray(const AProperty: TJsonSchemaProperty; AVariants: TObjectList<TJsonVariant>);
var
  varItem: TJsonVariant;
begin
  if AVariants.Count > 0 then
  begin
    FJsonWriter.WritePropertyName(AProperty.ToString);
    FJsonWriter.WriteStartArray;
    for varItem in AVariants do
    begin
      WriteAnyType(varItem);
    end;
    FJsonWriter.WriteEndArray;
  end;
end;

procedure TJsonSchemaWriter.WriteDependencies(ADependencies: TObjectList<TJsonDependency>);
var
  dep: TJsonDependency;
begin
  if ADependencies.Count > 0 then
  begin
    FJsonWriter.WritePropertyName(jsDependencies.ToString);
    FJsonWriter.WriteStartObject;
    for dep in ADependencies do
    begin
      if dep.DependencyType = dtProperty then
        WriteStringArray(dep.Name, dep.StringArray)
      else begin
        FJsonWriter.WritePropertyName(dep.Name);
        WriteJsonSchema(dep.Schema);
      end;
    end;
    FJsonWriter.WriteEndObject;
  end;
end;

procedure TJsonSchemaWriter.WriteJsonSchema(AJsonSchema: TJsonSchema);

  procedure WriteStringProperty(const AProperty: TJsonSchemaProperty; const AValue: String);
  begin
    if (AValue <> '') then
    begin
      FJsonWriter.WritePropertyName(AProperty.ToString);
      FJsonWriter.WriteValue(AValue);
    end;
  end;

  procedure WriteCardinalProperty(const AProperty: TJsonSchemaProperty; const AValue, ADefault: cardinal);
  begin
    if (AValue <> ADefault) then
    begin
      FJsonWriter.WritePropertyName(AProperty.ToString);
      FJsonWriter.WriteValue(AValue);
    end;
  end;

  procedure WriteBooleanProperty(const AProperty: TJsonSchemaProperty; const AValue, ADefault: Boolean);
  begin
    if (AValue <> ADefault) then
    begin
      FJsonWriter.WritePropertyName(AProperty.ToString);
      FJsonWriter.WriteValue(AValue);
    end;
  end;

  procedure WriteNumberProperty(const AProperty: TJsonSchemaProperty; const AValue: Double);
  begin
    if not IsNan(AValue) then
    begin
      FJsonWriter.WritePropertyName(AProperty.ToString);
      FJsonWriter.WriteValue(AValue);
    end;
  end;

begin
  FJsonWriter.WriteStartObject;
  WriteStringProperty(jsId, AJsonSchema.Id);
  WriteStringProperty(jsSchema, AJsonSchema.Schema);
  WriteStringProperty(jsTitle, AJsonSchema.Title);
  WriteStringProperty(jsDescription, AJsonSchema.Description);
  WriteSchemaObjects(jsDefinitions, AJsonSchema.Definitions.Properties);
  WriteTypes(AJsonSchema);
  WriteStringProperty(jsRef, AJsonSchema.Ref);
  WriteStringProperty(jsFormat, AJsonSchema.Format);
  WriteSchemaObjects(jsProperties, AJsonSchema.Properties);
  WriteSchemaObjects(jsPatternProperties, AJsonSchema.PatternProperties.Properties);
  WriteArray(jsEnum, AJsonSchema.Enum);
  WriteNumberProperty(jsMaximum, AJsonSchema.Maximum);
  WriteBooleanProperty(jsExclusiveMaximum, AJsonSchema.ExclusiveMaximum, false);
  WriteNumberProperty(jsMinimum, AJsonSchema.Minimum);
  WriteBooleanProperty(jsExclusiveMinimum, AJsonSchema.ExclusiveMinimum, false);
  WriteCardinalProperty(jsMaxLength, AJsonSchema.MaxLength, 0);
  WriteCardinalProperty(jsMinLength, AJsonSchema.MinLength, 0);
  WriteStringProperty(jsPattern, AJsonSchema.Pattern);
  WriteAnyTypeProperty(jsAdditionalItems, AJsonSchema.AdditionalItems);
  WriteAnyTypeProperty(jsAdditionalProperties, AJsonSchema.AdditionalProperties);
  if (AJsonSchema.Items.Count > 0) then
  begin
    FJsonWriter.WritePropertyName(jsItems.ToString);
    WriteJsonSchema(AJsonSchema.Items[0]);
  end;
  WriteCardinalProperty(jsMaxItems, AJsonSchema.MaxItems, 0);
  WriteCardinalProperty(jsMinItems, AJsonSchema.MinItems, 0);
  WriteBooleanProperty(jsUniqueItems, AJsonSchema.UniqueItems, false);
  WriteCardinalProperty(jsMaxProperties, AJsonSchema.MaxProperties, 0);
  WriteCardinalProperty(jsMinProperties, AJsonSchema.MinProperties, 0);
  WriteStringArray(jsRequired.ToString, AJsonSchema.Required);
  WriteSchemaArray(jsAllOf, AJsonSchema.AllOf);
  WriteSchemaArray(jsAnyOf, AJsonSchema.AnyOf);
  WriteSchemaArray(jsOneOf, AJsonSchema.OneOf);
  if AJsonSchema.NotSchema <> nil then
  begin
    FJsonWriter.WritePropertyName(jsNot.ToString);
    WriteJsonSchema(AJsonSchema.NotSchema);
  end;
  WriteDependencies(AJsonSchema.Dependencies);
  WriteAnyTypeProperty(jsDefault, AJsonSchema.DefaultValue);
  WriteSchemaList(AJsonSchema.NestedSchemas);
  FJsonWriter.WriteEndObject;
end;

procedure TJsonSchemaWriter.WriteSchemaArray(const AProperty: TJsonSchemaProperty; AJsonSchemaList: TObjectList<TJsonSchema>);
var
  jsonSchema: TJsonSchema;
begin
  if AJsonSchemaList.Count > 0 then
  begin
    FJsonWriter.WritePropertyName(AProperty.ToString);
    FJsonWriter.WriteStartArray;
    for jsonSchema in AJsonSchemaList do
    begin
      WriteJsonSchema(jsonSchema);
    end;
    FJsonWriter.WriteEndArray;
  end;
end;

procedure TJsonSchemaWriter.WriteSchemaList(AJsonSchemaList: TObjectList<TJsonSchema>);
var
  jsonSchema: TJsonSchema;
begin
  for jsonSchema in AJsonSchemaList do
  begin
    FJsonWriter.WritePropertyName(jsonSchema.Name);
    WriteJsonSchema(jsonSchema);
  end;
end;

procedure TJsonSchemaWriter.WriteSchemaObjects(const AProperty: TJsonSchemaProperty; AJsonSchemaList: TObjectList<TJsonSchema>);
begin
  if AJsonSchemaList.Count > 0 then
  begin
    FJsonWriter.WritePropertyName(AProperty.ToString);
    FJsonWriter.WriteStartObject;
    WriteSchemaList(AJsonSchemaList);
    FJsonWriter.WriteEndObject;
  end;
end;


procedure TJsonSchemaWriter.WriteStringArray(const AProperty: String; AStrings: TStrings);
var
  S: String;
begin
  if (AStrings.Count > 0) then
  begin
    FJsonWriter.WritePropertyName(AProperty);
    FJsonWriter.WriteStartArray;
    for S in AStrings do
    begin
      FJsonWriter.WriteValue(S);
    end;
    FJsonWriter.WriteEndArray;
  end;
end;

procedure TJsonSchemaWriter.WriteTypes(AJsonSchema: TJsonSchema);
var
  index: Integer;
  typeCount: Integer;
begin
  typeCount := Length(AJsonSchema.Types);
  if (typeCount > 0) then
  begin
    FJsonWriter.WritePropertyName(jsType.ToString);
    if (typeCount = 1) then
    begin
      FJsonWriter.WriteValue(AJsonSchema.Types[0].ToString);
    end
    else begin
      FJsonWriter.WriteStartArray;
      for index := 0 to Length(AJsonSchema.Types)-1 do
      begin
        FJsonWriter.WriteValue(AJsonSchema.Types[index].ToString);
      end;
      FJsonWriter.WriteEndArray;
    end;
  end;
end;

end.
