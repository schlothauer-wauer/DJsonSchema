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

unit JsonSchema.Keywords;

interface

type
  TJsonSchemaProperty = (
    jsUnknown,
    jsId,
    jsSchema,
    jsTitle,
    jsDescription,
    jsDefault,
    jsMultipleOf,
    jsMaximum,
    jsExclusiveMaximum,
    jsMinimum,
    jsExclusiveMinimum,
    jsMaxLength,
    jsMinLength,
    jsPattern,
    jsAdditionalItems,
    jsItems,
    jsMaxItems,
    jsMinItems,
    jsUniqueItems,
    jsMaxProperties,
    jsMinProperties,
    jsRequired,
    jsAdditionalProperties,
    jsDefinitions,
    jsProperties,
    jsPatternProperties,
    jsDependencies,
    jsEnum,
    jsType,
    jsAllOf,
    jsAnyOf,
    jsOneOf,
    jsNot,
    jsFormat,
    jsRef
  );

  TJsonSchemaPropertyHelper = record helper for TJsonSchemaProperty
    function ToString: String;
  end;

  function JsonSchemaPropertyFromStr(const S: String): TJsonSchemaProperty;

implementation

uses
  System.SysUtils;

{ TJsonSchemaPropertyHelper }

function TJsonSchemaPropertyHelper.ToString: String;
begin
  case self of
    jsUnknown: Result := '';
    jsId: Result := 'id';
    jsSchema: Result := '$schema';
    jsTitle: Result := 'title';
    jsDescription: Result := 'description';
    jsDefault: Result := 'default';
    jsMultipleOf: Result := 'multipleOf';
    jsMaximum: Result := 'maximum';
    jsExclusiveMaximum: Result := 'exclusiveMaximum';
    jsMinimum: Result := 'minimum';
    jsExclusiveMinimum: Result := 'exclusiveMinimum';
    jsMaxLength: Result := 'maxLength';
    jsMinLength: Result := 'minLength';
    jsPattern: Result := 'pattern';
    jsAdditionalItems: Result := 'additionalItems';
    jsItems: Result := 'items';
    jsMaxItems: Result := 'maxItems';
    jsMinItems: Result := 'minItems';
    jsUniqueItems: Result := 'uniqueItems';
    jsMaxProperties: Result := 'maxProperties';
    jsMinProperties: Result := 'minProperties';
    jsRequired: Result := 'required';
    jsAdditionalProperties: Result := 'additionalProperties';
    jsDefinitions: Result := 'definitions';
    jsProperties: Result := 'properties';
    jsPatternProperties: Result := 'patternProperties';
    jsDependencies: Result := 'dependencies';
    jsEnum: Result := 'enum';
    jsType: Result := 'type';
    jsAllOf: Result := 'allOf';
    jsAnyOf: Result := 'anyOf';
    jsOneOf: Result := 'oneOf';
    jsNot: Result := 'not';
    jsFormat: Result := 'format';
    jsRef: Result := '$ref';
  else
    raise Exception.Create('Unsupported JSON Schema Property');
  end;
end;

function JsonSchemaPropertyFromStr(const S: String): TJsonSchemaProperty;
var
  js: TJsonSchemaProperty;
begin
  for js := Low(TJsonSchemaProperty) to High(TJsonSchemaProperty) do
  begin
    if S = js.ToString then
    begin
      Result := js;
      exit;
    end;
  end;
  Result := jsUnknown;
end;

end.
