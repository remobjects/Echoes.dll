// Positive guards preserve optional defaults and omitted/expanded/explicit params
// arrays. Negative guards reject missing required arguments before params arrays.
namespace OptionalParameterTests;
uses System, System.Runtime.CompilerServices, RemObjects.Elements.Dynamic;
type
  Format = public enum (Compact = 0, HumanReadable = 7);
  Target = public class
  public
    method ParamsCount(params aValues: array of Integer): Integer;
    begin
      exit if assigned(aValues) then length(aValues) else -1;
    end;
    method OptionalAndParams(aFormat: Format := Format.HumanReadable; params aValues: array of Integer): Integer;
    begin
      exit Integer(aFormat) * 100 + length(aValues);
    end;
    method RequiredAndParams(aLabel: String; params aValues: array of Integer): Integer;
    begin
      exit length(aValues);
    end;
    method RequiredAndOptional(aNumber: Integer; aFormat: Format := Format.HumanReadable): Integer;
    begin
      exit aNumber + Integer(aFormat);
    end;
    method GenericParams<T>(params aValues: array of T): Integer;
    begin
      exit length(aValues);
    end;
    class method StaticParams(params aValues: array of String): Integer;
    begin
      exit length(aValues);
    end;
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
  ParamsConstructor = public class
  public
    property Count: Integer;
    constructor(params aValues: array of Integer);
    begin
      Count := length(aValues);
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
      if Integer(lTarget.ParamsCount()) <> 0 then
        raise new Exception('omitted params array');
      if Integer(lTarget.ParamsCount(4)) <> 1 then
        raise new Exception('one expanded params element');
      if Integer(lTarget.ParamsCount(4, 5)) <> 2 then
        raise new Exception('expanded params elements');
      if Integer(lTarget.ParamsCount(lArray)) <> 1 then
        raise new Exception('explicit params array');
      var lNull: Object := nil;
      if Integer(lTarget.ParamsCount(lNull)) <> -1 then
        raise new Exception('explicit null params array');
      if Integer(lTarget.OptionalAndParams()) <> 700 then
        raise new Exception('optional enum followed by omitted params');
      if Integer(lTarget.OptionalAndParams(Format.Compact, 1, 2)) <> 2 then
        raise new Exception('explicit enum followed by expanded params');
      var lStatic := CallSite<Func<CallSite, Object, Object>>.Create(
        OxygeneBinder.InvokeMember(OxygeneBinderFlags.StaticCall, 'StaticParams', nil, []));
      if Integer(lStatic.Target(lStatic, typeOf(Target))) <> 0 then
        raise new Exception('static omitted params');
      var lConstructor := CallSite<Func<CallSite, Object, Object>>.Create(
        OxygeneBinder.Invoke(OxygeneBinderFlags.StaticCall, []));
      if ParamsConstructor(lConstructor.Target(lConstructor, typeOf(ParamsConstructor))).Count <> 0 then
        raise new Exception('constructor omitted params');
      var lGeneric := CallSite<Func<CallSite, Object, Object>>.Create(
        OxygeneBinder.InvokeMember(OxygeneBinderFlags.None, 'GenericParams', [typeOf(String)], []));
      if Integer(lGeneric.Target(lGeneric, Object(lTarget))) <> 0 then
        raise new Exception('closed generic omitted params');
      var lText: dynamic := '5 + 3';
      var lWords := array of String(lText.Split());
      if (length(lWords) <> 3) or (lWords[0] <> '5') or (lWords[2] <> '3') then
        raise new Exception('String.Split omitted params');
      var lRejected := false;
      try
        lTarget.RequiredAndParams();
      except
        on OxygeneBinderException do
          lRejected := true;
      end;
      if not lRejected then
        raise new Exception('missing required prefix accepted');
      lRejected := false;
      try
        lTarget.RequiredAndOptional();
      except
        on OxygeneBinderException do
          lRejected := true;
      end;
      if not lRejected then
        raise new Exception('optional/default flags counted twice');
      Console.WriteLine('OK optional parameters');
    end;
  end;

end.
