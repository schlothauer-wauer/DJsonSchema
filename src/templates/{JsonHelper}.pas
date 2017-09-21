unit JsonHelper;

interface

uses
  System.Generics.Collections,
  System.JSON,
  System.JSON.Writers;

type
  TJsonHelper = record
  public
    class procedure ReadJsonArray(JsonArray: TJSONArray; AList: TList<Boolean>); overload; static;
    class procedure ReadJsonArray(JsonArray: TJSONArray; AList: TList<Double>); overload; static;
    class procedure ReadJsonArray(JsonArray: TJSONArray; AList: TList<Integer>); overload; static;
    class procedure ReadJsonArray(JsonArray: TJSONArray; AList: TList<String>); overload; static;
    class procedure WriteList(JsonWriter: TJsonWriter; AList: TList<String>); overload; static;
    class procedure WriteList(JsonWriter: TJsonWriter; AList: TList<Boolean>); overload; static;
    class procedure WriteList(JsonWriter: TJsonWriter; AList: TList<Integer>); overload; static;
    class procedure WriteList(JsonWriter: TJsonWriter; AList: TList<Double>); overload; static;
    class procedure WriteVariant(JsonWriter: TJsonWriter; AValue: Variant); static;
  end;

implementation

uses
  System.Classes, System.JSON.Types, System.Variants;

class procedure TJsonHelper.ReadJsonArray(JsonArray: TJSONArray; AList: TList<Boolean>);
var
  jsonValue: TJSONValue;
begin
  if JsonArray <> nil then
    for jsonValue in jsonArray do
    begin
      if jsonValue is TJSONBool then
        AList.Add(TJSONBool(jsonValue).AsBoolean);
    end;
end;

class procedure TJsonHelper.ReadJsonArray(JsonArray: TJSONArray; AList: TList<Double>);
var
  jsonValue: TJSONValue;
begin
  if JsonArray <> nil then
    for jsonValue in jsonArray do
    begin
      if jsonValue is TJSONNumber then
        AList.Add(TJSONNumber(jsonValue).AsDouble);
    end;
end;

class procedure TJsonHelper.ReadJsonArray(JsonArray: TJSONArray; AList: TList<Integer>);
var
  jsonValue: TJSONValue;
begin
  if JsonArray <> nil then
    for jsonValue in jsonArray do
    begin
      if jsonValue is TJSONNumber then
        AList.Add(TJSONNumber(jsonValue).AsInt);
    end;
end;

class procedure TJsonHelper.ReadJsonArray(JsonArray: TJSONArray; AList: TList<String>);
var
  jsonValue: TJSONValue;
begin
  if JsonArray <> nil then
    for jsonValue in jsonArray do
    begin
      AList.Add(jsonValue.Value);
    end;
end;

class procedure TJsonHelper.WriteList(JsonWriter: TJsonWriter; AList: TList<String>);
var
  item: String;
begin
  JsonWriter.WriteStartArray;
  for item in AList do
  begin
    JsonWriter.WriteValue(item);
  end;
  JsonWriter.WriteEndArray;
end;

class procedure TJsonHelper.WriteList(JsonWriter: TJsonWriter; AList: TList<Boolean>);
var
  item: Boolean;
begin
  JsonWriter.WriteStartArray;
  for item in AList do
  begin
    JsonWriter.WriteValue(item);
  end;
  JsonWriter.WriteEndArray;
end;

class procedure TJsonHelper.WriteList(JsonWriter: TJsonWriter; AList: TList<Integer>);
var
  item: Integer;
begin
  JsonWriter.WriteStartArray;
  for item in AList do
  begin
    JsonWriter.WriteValue(item);
  end;
  JsonWriter.WriteEndArray;
end;

class procedure TJsonHelper.WriteList(JsonWriter: TJsonWriter; AList: TList<Double>);
var
  item: Double;
begin
  JsonWriter.WriteStartArray;
  for item in AList do
  begin
    JsonWriter.WriteValue(item);
  end;
  JsonWriter.WriteEndArray;
end;

class procedure TJsonHelper.WriteVariant(JsonWriter: TJsonWriter; AValue: Variant);
begin
  case VarType(AValue) of
    varInteger, varShortInt, varByte, varWord:
      JsonWriter.WriteValue(integer(AValue));
    varBoolean:
      JsonWriter.WriteValue(boolean(AValue));
    varDouble, varSingle:
      JsonWriter.WriteValue(double(AValue));
    varString, varUString:
      JsonWriter.WriteValue(string(AValue));
  end;
end;

end.