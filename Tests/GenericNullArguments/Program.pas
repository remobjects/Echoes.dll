// Positive and negative runtime guards: known null arguments participate in generic
// and ordinary overload matching without inferring types or accepting non-nullable values.
namespace GenericNullArguments;
uses System, System.Runtime.CompilerServices, RemObjects.Elements.Dynamic;
type
  Methods = public static class
  public
    class method Pair<T>(aFirst, aSecond: T): T;
    begin
      exit aSecond;
    end;
    class method Gather<T>(params aValues: array of T): Integer;
    begin
      exit if aValues = nil then -1 else length(aValues);
    end;
    class method Text(aValue: String): String;
    begin
      exit if aValue = nil then 'null' else aValue;
    end;
    class method Number(aValue: nullable Integer): Integer;
    begin
      exit coalesce(aValue, -1);
    end;
    class method Pick(aValue: Object): String;
    begin
      exit 'object';
    end;
    class method Pick(aValue: String): String;
    begin
      exit 'string';
    end;
    class method Ambiguous(aValue: String): Integer;
    begin
      exit 1;
    end;
    class method Ambiguous(aValue: Uri): Integer;
    begin
      exit 2;
    end;
  end;

  Program = class
  private
    class field fChecks: Integer;

    class method Check(aExpected, anActual: Object; aMessage: String);
    begin
      if not Object.Equals(aExpected, anActual) then
        raise new Exception(aMessage);
      inc(fChecks);
    end;

    class method Call1(aName: String; aTypes: array of &Type := nil): CallSite<Func<CallSite, Object, Object, Object>>;
    begin
      exit CallSite<Func<CallSite, Object, Object, Object>>.Create(OxygeneBinder.InvokeMember(OxygeneBinderFlags.StaticCall, aName, aTypes, new OxygeneArgument[1]));
    end;

    class method Call2(aName: String; aTypes: array of &Type := nil): CallSite<Func<CallSite, Object, Object, Object, Object>>;
    begin
      exit CallSite<Func<CallSite, Object, Object, Object, Object>>.Create(OxygeneBinder.InvokeMember(OxygeneBinderFlags.StaticCall, aName, aTypes, new OxygeneArgument[2]));
    end;

  public
    class method Main;
    begin
      var lType := typeOf(Methods);
      var lPair := Call2('Pair');
      Check('value', lPair.Target(lPair, lType, nil, 'value'), 'Infer from the non-null argument');
      Check(nil, lPair.Target(lPair, lType, 'value', nil), 'Null second argument');
      Check('again', lPair.Target(lPair, lType, 'value', 'again'), 'Rebind the same site for non-null arguments');
      var lExplicit := Call2('Pair', [typeOf(String)]);
      Check(nil, lExplicit.Target(lExplicit, lType, nil, nil), 'Explicit reference type permits two nulls');
      var lRejected := false;
      try
        lPair.Target(lPair, lType, nil, nil);
      except
        on OxygeneBinderException do
          lRejected := true;
      end;
      Check(true, lRejected, 'Null arguments must not infer a generic type');
      var lValue := Call2('Pair', [typeOf(Integer)]);
      lRejected := false;
      try
        lValue.Target(lValue, lType, nil, 1);
      except
        on OxygeneBinderException do
          lRejected := true;
      end;
      Check(true, lRejected, 'Null must not satisfy a non-nullable value parameter');
      var lGather := Call2('Gather');
      Check(2, lGather.Target(lGather, lType, 1, 2), 'Expanded params inference remains supported');
      lGather := Call2('Gather', [typeOf(String)]);
      Check(2, lGather.Target(lGather, lType, 'value', nil), 'Expanded params accepts null elements');
      var lNullArray := Call1('Gather', [typeOf(String)]);
      Check(-1, lNullArray.Target(lNullArray, lType, nil), 'A single null can be the params array itself');
      var lText := Call1('Text');
      Check('null', lText.Target(lText, lType, nil), 'Non-generic reference parameter accepts null');
      var lNumber := Call1('Number');
      Check(-1, lNumber.Target(lNumber, lType, nil), 'Nullable value parameter accepts null');
      Check(3, lNumber.Target(lNumber, lType, 3), 'Nullable site rebinds for a non-null value');
      var lPick := Call1('Pick');
      Check('string', lPick.Target(lPick, lType, nil), 'Null selects the more specific reference overload');
      var lAmbiguous := Call1('Ambiguous');
      lRejected := false;
      try
        lAmbiguous.Target(lAmbiguous, lType, nil);
      except
        on OxygeneAmbigiousOverloadException do
          lRejected := true;
      end;
      Check(true, lRejected, 'Unrelated reference overloads remain ambiguous');
      writeLn($'PASS: {fChecks} dynamic null-argument checks');
    end;
  end;
end.
