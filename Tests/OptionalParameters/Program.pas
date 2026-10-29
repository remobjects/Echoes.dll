// Positive regression guards: dynamic calls preserve omitted and explicit optional defaults, including enums.
namespace OptionalParameterTests;
uses System;
type
  Format = public enum (Compact = 0, HumanReadable = 7);
  Target = public class
  public
    method EnumDefault(aFormat: Format := Format.HumanReadable): Integer;
    begin
      exit Integer(aFormat);
    end;
    method Defaults(aNumber: Integer := 12; aText: String := 'default'; aFlag: Boolean := true): String;
    begin
      exit aNumber.ToString + ':' + aText + ':' + aFlag.ToString;
    end;
    method ArrayDefault(aValue: array of Integer := nil): Integer;
    begin
      exit if assigned(aValue) then aValue[0] else -1;
    end;
    method NullDefault(aValue: Object := nil): Boolean;
    begin
      exit aValue = nil;
    end;
  end;
  Program = class
  public
    class method Main;
    begin
      var lTarget: dynamic := new Target;
      if Integer(lTarget.EnumDefault()) <> 7 then
        raise new Exception('omitted enum');
      if Integer(lTarget.EnumDefault(Format.Compact)) <> 0 then
        raise new Exception('explicit enum');
      if String(lTarget.Defaults()) <> '12:default:True' then
        raise new Exception('ordinary defaults');
      if String(lTarget.Defaults(4, 'given', false)) <> '4:given:False' then
        raise new Exception('explicit defaults');
      if not Boolean(lTarget.NullDefault()) then
        raise new Exception('null default');
      if Integer(lTarget.ArrayDefault()) <> -1 then
        raise new Exception('omitted array');
      var lArray: array of Integer := [9];
      if Integer(lTarget.ArrayDefault(lArray)) <> 9 then
        raise new Exception('explicit array');
      var lTypedJson := new RemObjects.Elements.RTL.JsonArray;
      var lJson: dynamic := lTypedJson;
      if String(lJson.ToJsonString()) <> lTypedJson.ToJsonString() then
        raise new Exception('JSON omitted format');
      if String(lJson.ToJsonString(RemObjects.Elements.RTL.JsonFormat.Minimal)) <> lTypedJson.ToJsonString(RemObjects.Elements.RTL.JsonFormat.Minimal) then
        raise new Exception('JSON explicit format');
      Console.WriteLine('OK optional parameters');
    end;
  end;

end.
