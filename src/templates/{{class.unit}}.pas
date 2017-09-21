unit {{class.unit}};

interface

uses
{{#class.units}}
  {{name}},
{{/class.units}}
  JsonSchemaTypes,
  System.Generics.Collections,
  System.JSON,
  System.JSON.Types,
  System.JSON.Writers;

type
  {{#json-schema.description}}
  /// <summary>{{json-schema.description}}</summary>
  {{/json-schema.description}}
  {{class.name}} = class(TObject)
  private
    {{#class.properties}}
    {{field}}: {{^date-time}}{{{type}}}{{/date-time}}{{#date-time}}TDateTimeString{{/date-time}};
    {{/class.properties}}
  public
    constructor Create;
    destructor Destroy; override;
    class function fromJSON(const json: String): {{class.name}};
    class function fromJSONValue(JsonValue: TJSONValue): {{class.name}};
    function toJSON(JsonFormatting: TJsonFormatting = TJsonFormatting.None): String;
    procedure WriteJSON(JsonWriter: TJsonWriter);
    class procedure ReadListFromJSON(JsonArray: TJSONArray; AList: TObjectList<{{class.name}}>);
    class procedure WriteListToJSON(JsonWriter: TJsonWriter; AList: TObjectList<{{class.name}}>);
    {{#class.properties}}
    {{#comment}}
    /// <summary>{{{comment}}}</summary>
    {{/comment}}
    property {{property}}: {{^date-time}}{{{type}}}{{/date-time}}{{#date-time}}TDateTimeString{{/date-time}} read {{field}} write {{field}};
  	{{/class.properties}}
  end;

implementation

uses
  System.Classes, System.SysUtils, System.Variants, JsonHelper;

{ {{class.name}} }

constructor {{class.name}}.Create;
begin
  inherited Create;
  {{#class.primitives}}
  {{#date-time}}
  {{field}} := TDateTimeString.Create;
  {{/date-time}}
  {{/class.primitives}}
  {{#class.lists}}
  {{field}} := {{{type}}}.Create;
  {{/class.lists}}
  {{#class.objectlists}}
  {{field}} := {{{type}}}.Create;
  {{/class.objectlists}}
end;

destructor {{class.name}}.Destroy;
begin
  {{#class.primitives}}
  {{#date-time}}
  {{field}}.Free;
  {{/date-time}}
  {{/class.primitives}}
  {{#class.allobjects}}
  {{field}}.Free;
  {{/class.allobjects}}
  inherited Destroy;
end;

class function {{class.name}}.fromJSON(const json: String): {{class.name}};
var
  jsonValue: TJSONValue;
begin
  jsonValue := TJSONObject.ParseJSONValue(json);
  try
    Result := {{class.name}}.fromJSONValue(jsonValue);
  finally
    jsonValue.Free;
  end;
end;

class function {{class.name}}.fromJSONValue(JsonValue: TJSONValue): {{class.name}};
begin
  if (JsonValue <> nil) then
  begin
    Result := {{class.name}}.Create;
    {{#class.primitives}}
    {{#required}}
    Result.{{property}}{{#date-time}}.Value{{/date-time}} := JsonValue.GetValue<{{type}}>('{{json_property}}');
    {{/required}}
    {{^required}}
    Result.{{property}}{{#date-time}}.Value{{/date-time}} := JsonValue.GetValue<{{type}}>('{{json_property}}', {{default}});
    {{/required}}
    {{/class.primitives}}
    {{#class.objects}}
    {{#required}}
    Result.{{property}} := {{type}}.fromJSONValue(JsonValue.GetValue<TJSONValue>('{{json_property}}'));
    {{/required}}
    {{^required}}
    Result.{{property}} := {{type}}.fromJSONValue(JsonValue.GetValue<TJSONValue>('{{json_property}}', nil));
    {{/required}}
    {{/class.objects}}
    {{#class.lists}}
    {{#required}}
    TJsonHelper.ReadJsonArray(JsonValue.GetValue<TJSONArray>('{{json_property}}'), Result.{{property}});
    {{/required}}
    {{^required}}
    TJsonHelper.ReadJsonArray(JsonValue.GetValue<TJSONArray>('{{json_property}}', nil), Result.{{property}});
    {{/required}}
    {{/class.lists}}
    {{#class.objectlists}}
    {{#required}}
    {{itemtype}}.ReadListFromJSON(JsonValue.GetValue<TJSONArray>('{{json_property}}'), Result.{{property}});
    {{/required}}
    {{^required}}
    {{itemtype}}.ReadListFromJSON(JsonValue.GetValue<TJSONArray>('{{json_property}}', nil), Result.{{property}});
    {{/required}}
    {{/class.objectlists}}
  end
  else
    Result := nil;
end;

class procedure {{class.name}}.ReadListFromJSON(JsonArray: TJSONArray; AList: TObjectList<{{class.name}}>);
var
  jsonValue: TJSONValue;
begin
  if (jsonArray <> nil) then
  begin
    for jsonValue in jsonArray do
    begin
      AList.Add({{class.name}}.fromJSONValue(jsonValue));
    end;
  end;
end;

function {{class.name}}.toJSON(JsonFormatting: TJsonFormatting): String;
var
  strWriter: TStringWriter;
  jsonWriter: TJsonTextWriter;
begin
  strWriter:= TStringWriter.Create;
  try
    jsonWriter := TJsonTextWriter.Create(strWriter);
    jsonWriter.Formatting := JsonFormatting;
    try
      WriteJson(jsonWriter);
      Result := strWriter.ToString;
    finally
      jsonWriter.Free;
    end;
  finally
    strWriter.Free;
  end;
end;

procedure {{class.name}}.WriteJSON(JsonWriter: TJsonWriter);
begin
  JsonWriter.WriteStartObject;
  {{#class.primitives}}
  {{#required}}
  JsonWriter.WritePropertyName('{{json_property}}');
  JsonWriter.WriteValue({{property}}{{#date-time}}.Value{{/date-time}});
  {{/required}}
  {{^required}}
  if ({{property}} <> {{default}}) then
  begin
    JsonWriter.WritePropertyName('{{json_property}}');
    JsonWriter.WriteValue({{property}}{{#date-time}}.Value{{/date-time}});
  end;
  {{/required}}
  {{/class.primitives}}
  {{#class.variants}}
  {{#required}}
  JsonWriter.WritePropertyName('{{json_property}}');
  TJsonHelper.WriteVariant(JsonWriter, {{property}});
  {{/required}}
  {{^required}}
  if not VarIsNull({{property}}) then
  begin
    JsonWriter.WritePropertyName('{{json_property}}');
    TJsonHelper.WriteVariant(JsonWriter, {{property}});
  end;
  {{/required}}
  {{/class.variants}}
  {{#class.objects}}
  {{#required}}
  JsonWriter.WritePropertyName('{{json_property}}');
  {{property}}.WriteJson(JsonWriter);
  {{/required}}
  {{^required}}
  if ({{property}} <> nil) then
  begin
    JsonWriter.WritePropertyName('{{json_property}}');
    {{property}}.WriteJson(JsonWriter);
  end;
  {{/required}}
  {{/class.objects}}
  {{#class.lists}}
  JsonWriter.WritePropertyName('{{json_property}}');
  TJsonHelper.WriteList(JsonWriter, {{property}});
  {{/class.lists}}
  {{#class.objectlists}}
  JsonWriter.WritePropertyName('{{json_property}}');
  {{itemtype}}.WriteListToJSON(JsonWriter, {{property}});
  {{/class.objectlists}}
  JsonWriter.WriteEndObject;
end;

class procedure {{class.name}}.WriteListToJSON(JsonWriter: TJsonWriter; AList: TObjectList<{{class.name}}>);
var
  item: {{class.name}};
begin
  JsonWriter.WriteStartArray;
  for item in AList do
  begin
    item.WriteJson(JsonWriter);
  end;
  JsonWriter.WriteEndArray;
end;

end.