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
