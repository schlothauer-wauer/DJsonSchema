unit JsonSchemaTypes;

interface

type
  TDateTimeString = class(TObject)
  private
    FValue: String;
  protected
    function GetAsDateTime: TDateTime;
    procedure SetAsDateTime(const AValue: TDateTime);
  public
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property Value: String read FValue write FValue;
  end;

implementation

uses
  Soap.XSBuiltIns;

function TDateTimeString.GetAsDateTime: TDateTime;
var
  xsDateTime: TXSDateTime;
begin
  xsDateTime := TXSDateTime.Create;
  try
    xsDateTime.XSToNative(Value);
    Result := xsDateTime.AsDateTime;
  finally
    xsDateTime.Free;
  end;
end;

procedure TDateTimeString.SetAsDateTime(const AValue: TDateTime);
var
  xsDateTime: TXSDateTime;
begin
  xsDateTime := TXSDateTime.Create;
  try
    xsDateTime.AsDateTime := AValue;
    Value := xsDateTime.NativeToXS;
  finally
    xsDateTime.Free;
  end;
end;

end.