(*******************************************************************************
 *
 * This file is part of the DJsonSchema project.
 * Copyright (C) 2017 Schlothauer & Wauer GmbH
 * https://github.com/schlothauer-wauer/DJsonSchema 
 *
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * https://www.mozilla.org/MPL/
 * 
 * Software distributed under the License is distributed on an "AS IS" basis, 
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License 
 * for the specific language governing rights and limitations under the License. 
 *
 * The Original Code is "JSON Schema Code Generator for Delphi".
 *
 * The Initial Developer of the Original Code is Schlothauer & Wauer GmbH. 
 * Portions created by the Initial Developer are Copyright (C) 2017 
 * the Initial Developer. All Rights Reserved. 
 *
 * Contributor(s): 
 *   Stephan Plath
 *
 ******************************************************************************)

unit JsonSchema.Reader;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.JSON.Readers,
  JsonSchema.Types, System.JSON.Types;

const
  DRAFT_04_SCHEMA = 'http://json-schema.org/draft-04/schema#';
  HYPER_SCHEMA = 'http://json-schema.org/draft-04/hyper-schema#';

type
  TJsonSchema = class;

  TJsonVariant = class(TObject)
  private
    FValue: Variant;
    FValueType: TSimpleType;
    FSchema: TJsonSchema;
    FVariantArray: TObjectList<TJsonVariant>;
    procedure SetValue(const AValue: Variant);
    procedure SetSchema(const Value: TJsonSchema);
  public
    constructor Create; overload;
    constructor Create(AValue: Variant); overload;
    destructor Destroy; override;
    function AsBoolean: boolean;
    function AsInteger: integer;
    function AsNumber: double;
    function AsString: String;
    function IsAssigned: Boolean;
    { Properties }
    property Value: Variant read FValue write SetValue;
    property ValueType: TSimpleType read FValueType write FValueType;
    property VariantArray: TObjectList<TJsonVariant> read FVariantArray;
    property Schema: TJsonSchema read FSchema write SetSchema;
  end;

  TDependencyType = (dtNone, dtProperty, dtSchema);

  TJsonDependency = class(TObject)
  private
    FParent: TJsonSchema;
    FName: String;
    FStringArray: TStrings;
    FDependencyType: TDependencyType;
    FSchema: TJsonSchema;
    function GetSchema: TJsonSchema;
    function GetStringArray: TStrings;
  public
    constructor Create(AParent: TJsonSchema);
    destructor Destroy; override;
    property DependencyType: TDependencyType read FDependencyType write FDependencyType;
    property Name: String read FName write FName;
    property StringArray: TStrings read GetStringArray;
    property Schema: TJsonSchema read GetSchema;
  end;

  TJsonSchema = class(TObject)
  private
    FParent: TJsonSchema;
    FName: String;
    FTitle: String;
    FId: String;
    FTypes: TArray<TSimpleType>;
    FDescription: String;
    FProperties: TObjectList<TJsonSchema>;
    FOptional: boolean;
    FMaximum: Double;
    FNestedSchemas: TObjectList<TJsonSchema>;
    FItems: TObjectList<TJsonSchema>;
    FSchema: String;
    FDefaultValue: TJsonVariant;
    FMinimum: Double;
    FPattern: String;
    FMaxLength: Cardinal;
    FMinLength: Cardinal;
    FMaxItems: Cardinal;
    FMinItems: Cardinal;
    FMinProperties: Cardinal;
    FMaxProperties: Cardinal;
    FRequired: TStringList;
    FFormat: String;
    FUniqueItems: Boolean;
    FExclusiveMaximum: Boolean;
    FExclusiveMinimum: Boolean;
    FAdditionalItems: TJsonVariant;
    FRef: String;
    FDefinitions: TJsonSchema;
    FAllOf: TObjectList<TJsonSchema>;
    FAnyOf: TObjectList<TJsonSchema>;
    FOneOf: TObjectList<TJsonSchema>;
    FAdditionalProperties: TJsonVariant;
    FEnum: TObjectList<TJsonVariant>;
    FDependencies: TObjectList<TJsonDependency>;
    FNotSchema: TJsonSchema;
    FPatternProperties: TJsonSchema;
    FSubschemaList: TObjectList<TJsonSchema>;
    function GetDefinitions: TJsonSchema;
    function GetPatternProperties: TJsonSchema;
  strict protected
    constructor Create(AParent: TJsonSchema);
  public
    constructor CreateRootSchema;
    destructor Destroy; override;
    function CreateSubschema: TJsonSchema;
    function Path: String;
    { Properties }
    property Name: String read FName write FName;
    property Id: String read FId write FId;
    property Title: String read FTitle write FTitle;
    property Types: TArray<TSimpleType> read FTypes;
    property DefaultValue: TJsonVariant read FDefaultValue write FDefaultValue;
    property Definitions: TJsonSchema read GetDefinitions;
    property Dependencies: TObjectList<TJsonDependency> read FDependencies;
    property Description: String read FDescription write FDescription;
    property Enum: TObjectList<TJsonVariant> read FEnum;
    property ExclusiveMaximum: Boolean read FExclusiveMaximum write FExclusiveMaximum;
    property ExclusiveMinimum: Boolean read FExclusiveMinimum write FExclusiveMinimum;
    property Format: String read FFormat write FFormat;
    property Items: TObjectList<TJsonSchema> read FItems;
    property AdditionalItems: TJsonVariant read FAdditionalItems write FAdditionalItems;
    property AdditionalProperties: TJsonVariant read FAdditionalProperties write FAdditionalProperties;
    property AllOf: TObjectList<TJsonSchema> read FAllOf;
    property AnyOf: TObjectList<TJsonSchema> read FAnyOf;
    property OneOf: TObjectList<TJsonSchema> read FOneOf;
    property Optional: boolean read FOptional write FOptional;
    property Maximum: Double read FMaximum write FMaximum;
    property Minimum: Double read FMinimum write FMinimum;
    property MaxItems: Cardinal read FMaxItems write FMaxItems;
    property MinItems: Cardinal read FMinItems write FMinItems;
    property MaxLength: Cardinal read FMaxLength write FMaxLength;
    property MinLength: Cardinal read FMinLength write FMinLength;
    property MaxProperties: Cardinal read FMaxProperties write FMaxProperties;
    property MinProperties: Cardinal read FMinProperties write FMinProperties;
    property NestedSchemas: TObjectList<TJsonSchema> read FNestedSchemas;
    property NotSchema: TJsonSchema read FNotSchema;
    property Pattern: String read FPattern write FPattern;
    property PatternProperties: TJsonSchema read GetPatternProperties;
    property Properties: TObjectList<TJsonSchema> read FProperties;
    property Ref: String read FRef write FRef;
    property Required: TStringList read FRequired write FRequired;
    property Schema: String read FSchema write FSchema;
    property UniqueItems: Boolean read FUniqueItems write FUniqueItems;
    property Subschemas: TObjectList<TJsonSchema> read FSubschemaList;
  end;

  JsonSchemaException = class(Exception);

  TJsonTokenTypes = set of TJsonToken;

  TJsonSchemaReader = class(TObject)
  private
    FJsonSchema: TJsonSchema;
  protected
    procedure Writeln(const S: String);
    function ReadBoolean(AReader: TJsonReader): Boolean;
    function ReadNumber(AReader: TJsonReader): Double;
    function ReadPositiveInteger(AReader: TJsonReader): cardinal;
    function ReadString(AReader: TJsonReader): String;
    procedure ReadVariantType(ASchema: TJsonSchema; AJsonVariant: TJsonVariant; AReader: TJsonReader;
      const AValidTypes: TJsonTokenTypes = []);
    procedure ReadArray(AJsonVariants: TObjectList<TJsonVariant>; AReader: TJsonReader; arrayLevel: integer = 0);
    procedure ReadDependencies(ASchema: TJsonSchema; AReader: TJsonReader);
    procedure ReadItems(ASchema: TJsonSchema; AReader: TJsonReader);
    procedure ReadProperties(ASchema: TJsonSchema; AReader: TJsonReader);
    procedure ReadSchema(ASchema: TJsonSchema; AReader: TJsonReader; nestedLevel: integer = 0);
    procedure ReadSchemaArray(ASchema: TJsonSchema; ASchemaList: TObjectList<TJsonSchema>; AReader: TJsonReader; arrayLevel: integer = 0);
    procedure ReadStringArray(AStrings: TStrings; AReader: TJsonReader);
    procedure ReadTypes(AJsonSchema: TJsonSchema; AReader: TJsonReader);
  public
    constructor Create;
    destructor Destroy; override;
    procedure ReadFromFile(const AFilename: String);
    procedure ReadFromStream(AStream: TStream);
    procedure ReadFromString(const AString: String);
    property JsonSchema: TJsonSchema read fJsonSchema;
  end;

implementation

uses
  Winapi.Windows, System.StrUtils, JsonSchema.Keywords, System.Math, System.Variants;

{ TJsonSchemaReader }

constructor TJsonSchemaReader.Create;
begin
  FJsonSchema := TJsonSchema.CreateRootSchema;
end;

destructor TJsonSchemaReader.Destroy;
begin
  FJsonSchema.Free;
  inherited;
end;

procedure TJsonSchemaReader.ReadVariantType(ASchema: TJsonSchema; AJsonVariant: TJsonVariant; AReader: TJsonReader; const AValidTypes: TJsonTokenTypes);
begin
  if AReader.Read then
  begin
    if (AValidTypes = []) or (AReader.TokenType in AValidTypes) then
    begin
      case AReader.TokenType of
        TJsonToken.StartObject:
        begin
          AJsonVariant.ValueType := stObject;
          AJsonVariant.Schema := ASchema.CreateSubschema;
          ReadSchema(AJsonVariant.Schema, AReader, 1);
        end;
        TJsonToken.StartArray:
        begin
          AJsonVariant.ValueType := stArray;
          ReadArray(AJsonVariant.VariantArray, AReader, 1);
        end;
        TJsonToken.Integer:
        begin
          AJsonVariant.ValueType := stInteger;
          AJsonVariant.Value := AReader.Value.AsInteger;
        end;
        TJsonToken.Float:
        begin
          AJsonVariant.ValueType := stNumber;
          AJsonVariant.Value := AReader.Value.AsExtended;
        end;
        TJsonToken.String:
        begin
          AJsonVariant.ValueType := stString;
          AJsonVariant.Value := AReader.Value.AsString;
        end;
        TJsonToken.Boolean:
        begin
          AJsonVariant.ValueType := stBoolean;
          AJsonVariant.Value := AReader.Value.AsBoolean;
        end;
        TJsonToken.Null:
        begin
          AJsonVariant.ValueType := stNull;
        end;
      end;
    end
    else raise JsonSchemaException.CreateFmt('Unexpected token type: %s', [AReader.Value.ToString]);
  end;
end;

procedure TJsonSchemaReader.ReadArray(AJsonVariants: TObjectList<TJsonVariant>; AReader: TJsonReader; arrayLevel: integer);
begin
  while AReader.Read do
  begin
    case Areader.TokenType of
      TJsonToken.StartArray:
      begin
        Inc(arrayLevel);
      end;
      TJsonToken.String:
      begin
        AJsonVariants.Add(TJsonVariant.Create(AReader.Value.AsString));
      end;
      TJsonToken.Integer:
      begin
        AJsonVariants.Add(TJsonVariant.Create(AReader.Value.AsInteger));
      end;
      TJsonToken.Boolean:
      begin
        AJsonVariants.Add(TJsonVariant.Create(AReader.Value.AsBoolean));
      end;
      TJsonToken.Float:
      begin
        AJsonVariants.Add(TJsonVariant.Create(AReader.Value.AsExtended));
      end;
      TJsonToken.Null:
      begin
        AJsonVariants.Add(TJsonVariant.Create(null));
      end;
      TJsonToken.EndArray:
      begin
        Dec(arrayLevel);
        if arrayLevel = 0 then
          break;
      end
    else
      raise JsonSchemaException.CreateFmt('Unexpected array token: %s', [AReader.Value.ToString]);
    end;
  end;
end;

function TJsonSchemaReader.ReadBoolean(AReader: TJsonReader): Boolean;
begin
  if AReader.Read and (AReader.TokenType in [TJsonToken.Boolean]) then
  begin
    Exit(AReader.Value.AsBoolean);
  end;
  raise JsonSchemaException.CreateFmt('Unexpected boolean token: %s', [AReader.Value.ToString]);
end;

procedure TJsonSchemaReader.ReadDependencies(ASchema: TJsonSchema; AReader: TJsonReader);
var
  nestedLevel: integer;
  dependency: TJsonDependency;
begin
  nestedLevel := 0;
  while AReader.Read do
  begin
    case AReader.TokenType of
      TJsonToken.PropertyName:
      begin
        dependency := TJsonDependency.Create(ASchema);
        dependency.Name := AReader.Value.AsString;
        ASchema.Dependencies.Add(dependency);
        if AReader.Read then
        case AReader.TokenType of
          TJsonToken.StartArray: ReadStringArray(dependency.StringArray, AReader);
          TJsonToken.StartObject: ReadSchema(dependency.Schema, AReader);
        else
          raise JsonSchemaException.CreateFmt('Unexpected dependency token: %s', [AReader.Value.ToString]);
        end;
      end;
      TJsonToken.StartObject:
      begin
        Inc(nestedLevel);
      end;
      TJsonToken.EndObject:
      begin
        Dec(nestedLevel);
        if (nestedLevel = 0) then
          break;
      end;
    end;
  end;
end;

procedure TJsonSchemaReader.ReadFromFile(const AFilename: String);
var
  fileStream: TFileStream;
begin
  fileStream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    ReadFromStream(fileStream);
    FJsonSchema.Name := ChangeFileExt(ExtractFileName(AFilename), '');
  finally
    fileStream.Free;
  end;
end;

procedure TJsonSchemaReader.ReadFromStream(AStream: TStream);
var
  reader: TStreamReader;
  jsonReader: TJsonTextReader;
begin
  reader := TStreamReader.Create(AStream);
  try
    jsonReader := TJsonTextReader.Create(reader);
    try
      try
        ReadSchema(FJsonSchema, jsonReader);
      except
        on E: Exception do
        begin
          raise JsonSchemaException.CreateFmt('Error at JSON path [%s]: %s', [jsonReader.Path, E.Message]);
        end;
      end;
    finally
      jsonReader.Free;
    end;
  finally
    reader.Free;
  end;
end;

procedure TJsonSchemaReader.ReadFromString(const AString: String);
var
  stream: TStringStream;
begin
  stream := TStringStream.Create(AString, TEncoding.UTF8);
  try
    ReadFromStream(stream);
  finally
    stream.Free;
  end;
end;

procedure TJsonSchemaReader.ReadItems(ASchema: TJsonSchema; AReader: TJsonReader);
var
  itemSchema: TJsonSchema;
begin
  if AReader.Read then
  begin
    case AReader.TokenType of
      TJsonToken.StartObject:
      begin
        itemSchema := ASchema.CreateSubschema;
        itemSchema.Name := 'items';
        ASchema.Items.Add(itemSchema);
        ReadSchema(itemSchema, AReader, 1);
      end;
      TJsonToken.StartArray:
      begin
        ReadSchemaArray(ASchema, ASchema.Items, AReader, 1);
      end;
    else
      raise JsonSchemaException.CreateFmt('Unexpected token: %s', [AReader.Value.ToString]);
    end;
  end;
end;

function TJsonSchemaReader.ReadNumber(AReader: TJsonReader): Double;
begin
  if AReader.Read and (AReader.TokenType in [TJsonToken.Float, TJsonToken.Integer]) then
  begin
    Exit(AReader.Value.AsExtended);
  end;
  raise JsonSchemaException.CreateFmt('Unexpected number token: %s', [AReader.Value.ToString]);
end;

function TJsonSchemaReader.ReadPositiveInteger(AReader: TJsonReader): cardinal;
begin
  if AReader.Read and (AReader.TokenType in [TJsonToken.Integer]) then
  begin
    Result := AReader.Value.AsInteger;
    Exit;
  end;
  raise JsonSchemaException.CreateFmt('Unexpected integer token: %s', [AReader.Value.ToString]);
end;

procedure TJsonSchemaReader.ReadProperties(ASchema: TJsonSchema; AReader: TJsonReader);
var
  nestedLevel: integer;
  propName: String;
  schemaItem: TJsonSchema;
begin
  nestedLevel := 0;
  while AReader.Read do
  begin
    case AReader.TokenType of
      TJsonToken.PropertyName:
      begin
        propName := AReader.Value.ToString;
        schemaItem := ASchema.CreateSubschema;
        schemaItem.Name := propName;
        ASchema.Properties.Add(schemaItem);
        ReadSchema(schemaItem, AReader);
      end;
      TJsonToken.StartObject:
      begin
        inc(nestedLevel);
      end;
      TJsonToken.EndObject:
      begin
        dec(nestedLevel);
        if (nestedLevel <= 0) then
          break;
      end;
    end;
  end;
end;

procedure TJsonSchemaReader.ReadSchema(ASchema: TJsonSchema; AReader: TJsonReader; nestedLevel: integer);
var
  propName: String;
  nestedSchema: TJsonSchema;
begin
  while AReader.Read do
  begin
    case AReader.TokenType of
      TJsonToken.PropertyName:
      begin
        propName := AReader.Value.ToString;
        case JsonSchemaPropertyFromStr(propName) of
          jsItems: ReadItems(ASchema, AReader);
          jsDefinitions: ReadProperties(ASchema.Definitions, AReader);
          jsProperties: ReadProperties(ASchema, AReader);
          jsDependencies: ReadDependencies(ASchema, AReader);
          jsType: ReadTypes(ASchema, AReader);
          jsDescription: ASchema.Description := ReadString(AReader);
          jsTitle: ASchema.Title := ReadString(AReader);
          jsDefault: ReadVariantType(ASchema, ASchema.DefaultValue, AReader);
          jsSchema: ASchema.Schema := ReadString(AReader);
          jsId: ASchema.Id := ReadString(AReader);
          jsMinimum: ASchema.Minimum := ReadNumber(AReader);
          jsMaximum: ASchema.Maximum := ReadNumber(AReader);
          jsMaxItems: ASchema.MaxItems := ReadPositiveInteger(AReader);
          jsMinItems: ASchema.MinItems := ReadPositiveInteger(AReader);
          jsMaxLength: ASchema.MaxLength := ReadPositiveInteger(AReader);
          jsMinLength: ASchema.MinLength := ReadPositiveInteger(AReader);
          jsMaxProperties: ASchema.MaxProperties := ReadPositiveInteger(AReader);
          jsMinProperties: ASchema.MinProperties := ReadPositiveInteger(AReader);
          jsUniqueItems: ASchema.UniqueItems := ReadBoolean(AReader);
          jsExclusiveMaximum: ASchema.ExclusiveMaximum := ReadBoolean(AReader);
          jsExclusiveMinimum: ASchema.ExclusiveMinimum := ReadBoolean(AReader);
          jsEnum: ReadArray(ASchema.Enum, AReader);
          jsAdditionalItems: ReadVariantType(ASchema, ASchema.AdditionalItems, AReader, [TJsonToken.Boolean, TJsonToken.StartObject]);
          jsAdditionalProperties: ReadVariantType(ASchema, ASchema.AdditionalProperties, AReader, [TJsonToken.Boolean, TJsonToken.StartObject]);
          jsPattern: ASchema.Pattern := ReadString(AReader);
          jsPatternProperties: ReadProperties(ASchema.PatternProperties, AReader);
          jsRequired: ReadStringArray(ASchema.Required, AReader);
          jsFormat: ASchema.Format := ReadString(AReader);
          jsRef: ASchema.Ref := ReadString(AReader);
          jsAllOf: ReadSchemaArray(ASchema, ASchema.AllOf, AReader);
          jsAnyOf: ReadSchemaArray(ASchema, ASchema.AnyOf, AReader);
          jsOneOf: ReadSchemaArray(ASchema, ASchema.OneOf, AReader);

          jsNot:
          begin
            ASchema.FNotSchema := ASchema.CreateSubschema;
            ReadSchema(ASchema.NotSchema, AReader);
          end;

          // nested schema
          jsUnknown:
          begin
            nestedSchema := ASchema.CreateSubschema;
            nestedSchema.Name := AReader.Value.ToString;
            ASchema.NestedSchemas.Add(nestedSchema);
            ReadSchema(nestedSchema, AReader);
          end;
        end;
      end;
      TJsonToken.StartObject:
      begin
        inc(nestedLevel);
      end;
      TJsonToken.EndObject:
      begin
        dec(nestedLevel);
        if (nestedLevel <= 0) then
          break;
      end;
    end;
  end;
end;

procedure TJsonSchemaReader.ReadSchemaArray(ASchema: TJsonSchema; ASchemaList: TObjectList<TJsonSchema>; AReader: TJsonReader; arrayLevel: integer);
var
  schemaItem: TJsonSchema;
begin
  while AReader.Read do
  begin
    case Areader.TokenType of
      TJsonToken.StartArray:
      begin
        inc(arrayLevel);
      end;
      TJsonToken.StartObject:
      begin
        if (arrayLevel = 1) then
        begin
          schemaItem := ASchema.CreateSubschema;
          ASchemaList.Add(schemaItem);
          ReadSchema(schemaItem, AReader, 1);
        end;
      end;
      TJsonToken.EndArray:
      begin
        dec(arrayLevel);
        if (arrayLevel = 0) then
          break;
      end
      else begin
        raise JsonSchemaException.CreateFmt('Unexpected token: %s', [AReader.Value.ToString]);
      end;
    end;
  end;
end;

function TJsonSchemaReader.ReadString(AReader: TJsonReader): String;
begin
  if AReader.Read and (AReader.TokenType = TJsonToken.String) then
  begin
    Exit(AReader.Value.ToString);
  end;
  raise JsonSchemaException.CreateFmt('Unexpected string token: %s', [AReader.Value.ToString]);
end;

procedure TJsonSchemaReader.ReadStringArray(AStrings: TStrings; AReader: TJsonReader);
begin
  while AReader.Read do
  begin
    case Areader.TokenType of
      TJsonToken.StartArray: ;
      TJsonToken.String:
        AStrings.Add(AReader.Value.ToString);
      TJsonToken.EndArray:
        break;
    else
      raise JsonSchemaException.CreateFmt('Unexpected token: %s', [AReader.Value.ToString]);
    end;
  end;
end;

procedure TJsonSchemaReader.ReadTypes(AJsonSchema: TJsonSchema; AReader: TJsonReader);
var
  arrayLevel: integer;
  len: Integer;
begin
  arrayLevel := 0;
  while AReader.Read do
  begin
    case AReader.TokenType of
      TJsonToken.StartArray: Inc(arrayLevel);
      TJsonToken.String:
      begin
        len := Length(AJsonSchema.Types);
        SetLength(AJsonSchema.FTypes, len+1);
        AJsonSchema.Types[len] := StringToSimpleType(AReader.Value.AsString);
        if arrayLevel = 0 then
          Exit;
      end;
      TJsonToken.EndArray:
      begin
        Dec(arrayLevel);
        if (arrayLevel <= 0) then
          break;
      end
    else
      raise JsonSchemaException.CreateFmt('Unexpected type token: %s', [AReader.Value.ToString]);
    end;
  end;
end;

procedure TJsonSchemaReader.Writeln(const S: String);
begin
  OutputDebugString(PChar(S));
  System.Writeln(S);
end;

{ TJsonSchemaObject }

constructor TJsonSchema.Create(AParent: TJsonSchema);
begin
  FParent := AParent;
  FSubschemaList := TObjectList<TJsonSchema>.Create(false);
  SetLength(FTypes, 0);
  FItems := TObjectList<TJsonSchema>.Create;
  FProperties := TObjectList<TJsonSchema>.Create;
  FNestedSchemas := TObjectList<TJsonSchema>.Create;
  FRequired := TStringList.Create;
  FEnum := TObjectList<TJsonVariant>.Create;
  FAllOf := TObjectList<TJsonSchema>.Create;
  FAnyOf := TObjectList<TJsonSchema>.Create;
  FOneOf := TObjectList<TJsonSchema>.Create;
  FNotSchema := nil;
  FDependencies := TObjectList<TJsonDependency>.Create;
  FMaximum := NaN;
  FMinimum := NaN;
  FDefaultValue := TJsonVariant.Create;
  FAdditionalItems := TJsonVariant.Create;
  FAdditionalProperties := TJsonVariant.Create;
end;

constructor TJsonSchema.CreateRootSchema;
begin
  Create(nil);
end;

function TJsonSchema.CreateSubschema: TJsonSchema;
begin
  Result := TJsonSchema.Create(self);
  FSubschemaList.Add(Result);
end;

destructor TJsonSchema.Destroy;
begin
  FSubschemaList.Free;
  FDefaultValue.Free;
  FDefinitions.Free;
  FDependencies.Free;
  FItems.Free;
  FProperties.Free;
  FPatternProperties.Free;
  FNestedSchemas.Free;
  FRequired.Free;
  FEnum.Free;
  FAllOf.Free;
  FAnyOf.Free;
  FOneOf.Free;
  FNotSchema.Free;
  FAdditionalItems.Free;
  FAdditionalProperties.Free;
  inherited Destroy;
end;

function TJsonSchema.GetDefinitions: TJsonSchema;
begin
  if FDefinitions = nil then
  begin
    FDefinitions := CreateSubschema;
    FDefinitions.Name := jsDefinitions.ToString;
  end;
  Result := FDefinitions;
end;

function TJsonSchema.GetPatternProperties: TJsonSchema;
begin
  if FPatternProperties = nil then
  begin
    FPatternProperties := CreateSubschema;
    FPatternProperties.Name := jsPatternProperties.ToString;
  end;
  Result := FPatternProperties;
end;

function TJsonSchema.Path: String;
begin
  if FParent = nil then
    Result := '#'
  else
    Result := FParent.Path + '/' + Name;
end;

{ TJsonDependency }

constructor TJsonDependency.Create(AParent: TJsonSchema);
begin
  FParent := AParent;
end;

destructor TJsonDependency.Destroy;
begin
  FStringArray.Free;
  FSchema.Free;
  inherited;
end;

function TJsonDependency.GetSchema: TJsonSchema;
begin
  FDependencyType := dtSchema;
  if FSchema = nil then
  begin
    FSchema := FParent.CreateSubschema;
  end;
  Result := FSchema;
end;

function TJsonDependency.GetStringArray: TStrings;
begin
  FDependencyType := dtProperty;
  if FStringArray = nil then
  begin
    FStringArray := TStringList.Create;
  end;
  Result := FStringArray;
end;

{ TJsonVariant }

function TJsonVariant.AsBoolean: Boolean;
begin
  Result := FValue;
end;

function TJsonVariant.AsInteger: integer;
begin
  Result := FValue;
end;

function TJsonVariant.AsNumber: Double;
begin
  Result := FValue;
end;

function TJsonVariant.AsString: String;
begin
  Result := FValue;
end;

constructor TJsonVariant.Create;
begin
  FValue := Unassigned;
  FValueType := stNone;
  FVariantArray := TObjectList<TJsonVariant>.Create;
end;

constructor TJsonVariant.Create(AValue: Variant);
begin
  Create;
  SetValue(AValue);
end;

destructor TJsonVariant.Destroy;
begin
  FVariantArray.Free;
  FSchema.Free;
  inherited Destroy;
end;

function TJsonVariant.IsAssigned: Boolean;
begin
  Result := not VarIsEmpty(FValue);
end;

procedure TJsonVariant.SetSchema(const Value: TJsonSchema);
begin
  FSchema := Value;
  FValueType := stObject;
end;

procedure TJsonVariant.SetValue(const AValue: Variant);
begin
  FValue := AValue;
  case VarType(AValue) of
    varNull:
      FValueType := stNull;
    varBoolean:
      FValueType := stBoolean;
    varSmallint, varShortInt, varInteger:
      FValueType := stInteger;
    varString, varUString:
      FValueType := stString;
    varSingle, varDouble:
      FValueType := stNumber;
  else
    raise JsonSchemaException.CreateFmt('Unsupported value type: %d', [VarType(Value)]);
  end;
end;

end.
