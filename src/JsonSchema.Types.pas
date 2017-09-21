unit JsonSchema.Types;

interface

type
  // JSON Schema primitive types
  TSimpleType = (
    stNone,
    stArray,
    stBoolean,
    stInteger,
    stNull,     // A JSON number without a fraction or exponent part.
    stNumber,   // Any JSON number.  Number includes integer.
    stObject,
    stString);

  TSimpleTypes = set of TSimpleType;

  TSimpleTypeHelper = record helper for TSimpleType
    function ToString: String;
  end;

  function StringToSimpleType(const S: String): TSimpleType;

implementation

{ TSimpleTypeHelper }

function TSimpleTypeHelper.ToString: String;
begin
  case self of
    stNone: Result := '';
    stArray: Result := 'array';
    stBoolean: Result := 'boolean';
    stInteger: Result := 'integer';
    stNull: Result := 'null';
    stNumber: Result := 'number';
    stObject: Result := 'object';
    stString: Result := 'string';
  else
    Result := 'any';
  end;
end;

function StringToSimpleType(const S: String): TSimpleType;
var
  st: TSimpleType;
begin
  for st := Low(TSimpleType) to High(TSimpleType) do
  begin
    if S = st.ToString then
      exit(st);
  end;
  Result := stNone;
end;


end.
