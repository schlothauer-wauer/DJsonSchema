unit TestAssertUtils;

interface

uses
  Windows, Classes, SysUtils;

type

  AssertUtils = class
    /// <summary> Vergleicht den Inhalt der String-Listen miteinander. </summary>
    /// <param name="expected">String-Liste mit dem erwarteten Inhalt</param>
    /// <param name="actual">String-Liste mit dem tatsächlichen Inhalt</param>
    /// <param name="ignoreLineNumbers">Zeilennummern, die beim Vergleich ignoriert werden sollen, z.B. [] (keine Zeilen ignorieren) oder [5] (Zeile 5 ignorieren)</param>
    class procedure CheckEquals(expected: TStrings; actual: TStrings; const ignoreLineNumbers: array of integer); overload;

    class procedure CheckEquals(const ExpectedFile: String; actual: TStrings; const ignoreLineNumbers: array of integer); overload;


    /// <summary>Vergleicht die Strings miteinander und erzeugt ggf. einen <c>ETestFailure</c> (Fail) mit der Position des ersten Unterschieds.</summary>
    class procedure CheckString(const Expected, Actual: String; const PreMsg: String = '');

    /// <summary> Vergleicht den Inhalt der Dateien miteinander. </summary>
    class procedure CheckEqualFiles(const ExpectedFile, ActualFile: String; const ignoreLineNumbers: array of integer;
      const CreateCopyOnFailure: Boolean = true);

  end;


implementation

uses
  System.Generics.Collections, DUnitX.Assert, DUnitX.Init,
  DUnitX.TestFramework, DUnitX.Exceptions;


resourcestring
  StringDiffersAtPosition = 'Der erwartete String <%s> unterscheidet sich vom ' +
  'aktuellen String <%s> an Position %d';

function DiffPos(const S1, S2: String): integer;
var
  len1, len2: integer;
  index: Integer;
begin
  len1 := Length(S1);
  len2 := Length(S2);
  if (len1 <> len2) then
  begin
    if len1 > len2
      then result := len1
      else result := len2;
  end
  else result := 0;

  for index := 1 to len1 do
  begin
    if (index <= len2) then
    begin
      if S1[index] <> S2[index] then
      begin
        result := index;
        exit;
      end;
    end;
  end;
end;

class procedure AssertUtils.CheckEquals(expected, actual: TStrings; const ignoreLineNumbers: array of integer);
var
  index: Integer;
  lineNumber: integer;
  ignoreLinesDict: TDictionary<Integer, Boolean>;
  diff: Integer;
begin
  ignoreLinesDict := TDictionary<Integer,Boolean>.Create;
  try
    if (Length(ignoreLineNumbers) > 0) then
    begin
      for index := 0 to Length(ignoreLineNumbers)-1 do
      begin
        ignoreLinesDict.Add(ignoreLineNumbers[index], true);
      end;
    end;

    Assert.IsTrue(expected <> actual);
    Assert.AreEqual(expected.Count, actual.Count, 'Anzahl der Strings ist unterschiedlich');
    for index := 0 to expected.Count - 1 do
    begin
      lineNumber := index + 1;
      if (ignoreLinesDict.ContainsKey(lineNumber)) then
      begin
        OutputDebugString(PChar('CheckEquals: Ignoriere Zeile ' + IntToStr(lineNumber) + ':' + actual[index]));
      end
      else begin
        if (expected[index] <> actual[index]) then
        begin
          diff := DiffPos(expected[index], actual[index]);
          Assert.Fail(Format('Unterschied in Zeile %d, Position %d:'#13#10'Erwartet: %s'#13#10'Erhalten: %s',
            [lineNumber, diff, expected[index], actual[index]]));
        end;
      end;
    end;
  finally
    ignoreLinesDict.Free;
  end;
end;

class procedure AssertUtils.CheckEqualFiles(const ExpectedFile, ActualFile: String; const ignoreLineNumbers: array of integer;
  const CreateCopyOnFailure: Boolean);
var
  actual: TStringList;
begin
  actual := TStringList.Create;
  try
    actual.LoadFromFile(ActualFile);
    try
      CheckEquals(ExpectedFile, actual, ignoreLineNumbers);

    except
      on E: ETestFailure do
      begin
        // Kopie erzeugen, um leichteren Vergleich zu ermöglichen
        if CreateCopyOnFailure then
          CopyFile(PChar(ActualFile), PChar(ExpectedFile + '~'), false);
        raise;
      end;
    end;
  finally
    actual.Free;
  end;
end;

class procedure AssertUtils.CheckEquals(const ExpectedFile: String; actual: TStrings; const ignoreLineNumbers: array of integer);
var
  expected: TStringList;
begin
  expected := TStringList.Create;
  try
    if not FileExists(ExpectedFile) then
    begin
      ForceDirectories(ExtractFilePath(ExpectedFile));
      actual.SaveToFile(ExpectedFile);
    end;
    expected.LoadFromFile(ExpectedFile);
    try
      CheckEquals(expected, actual, ignoreLineNumbers);
    except
      on E: ETestFailure do
      begin
        raise ETestFailure.CreateFmt('Datei %s: ' + E.Message, [ExpectedFile]);
      end;
    end;
  finally
    expected.Free;
  end;
end;

class procedure AssertUtils.CheckString(const Expected, Actual: String; const PreMsg: String = '');

  function GetChar(const ch: char): String;
  begin
    if ch > #32 then
      Result := '''' + ch + ''''
    else
      Result := '#' + Ord(ch).ToString;
  end;

var
  index: Integer;
  actLen, expLen: Integer;
begin
  expLen := Length(Expected);
  actLen := Length(Actual);
  for index := 1 to expLen do
  begin
    if (index > actLen) or (Expected[index] <> Actual[index]) then
    begin
      Assert.Fail(Format(PreMsg + StringDiffersAtPosition, [Expected, Actual, index]) + ': ' +
        GetChar(Expected[index]) + ' <> ' + GetChar(Actual[index]));
    end;
  end;
  if actLen > expLen then
  begin
    Assert.Fail(Format(PreMsg + StringDiffersAtPosition, [Expected, Actual, expLen + 1]));
  end;
end;

end.

