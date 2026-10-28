// Dynamic tuple reads must handle changing indices, tuple shapes, Rest, and invalid indices.
namespace TupleIndexTests;

uses System, System.Collections.Generic, RemObjects.Elements.Dynamic;

type
  FirstValue = class
  public
    constructor(aValue: Integer); begin Value := aValue; end;
    property Value: Integer;
  end;
  SecondValue = class
  public
    constructor(aValue: Integer); begin Value := aValue * 2; end;
    property Value: Integer;
  end;
  Program = class
  public
    class method Read(aValue: dynamic; aIndex: Integer): dynamic;
    begin
      exit aValue[aIndex];
    end;

    class method Construct(aType: dynamic; aValue: Integer): dynamic;
    begin
      exit aType(aValue);
    end;

    class method Main;
    begin
      var lPair := new Tuple<Integer, String>(7, 'eight');
      if Integer(Read(lPair, 0)) <> 7 then
        raise new Exception('first');
      if String(Read(lPair, 1)) <> 'eight' then
        raise new Exception('second');
      if Integer(Read(new Tuple<Integer>(9), 0)) <> 9 then
        raise new Exception('shape');
      var lLong := new Tuple<Integer, Integer, Integer, Integer, Integer, Integer, Integer, Tuple<String, Integer>>(1, 2, 3, 4, 5, 6, 7, new Tuple<String, Integer>('rest', 9));
      if String(Read(lLong, 7)) <> 'rest' then
        raise new Exception('rest first');
      if Integer(Read(lLong, 8)) <> 9 then
        raise new Exception('rest second');
      var lValue := new ValueTuple<Integer, String>(10, 'value');
      if Integer(Read(lValue, 0)) <> 10 then
        raise new Exception('value first');
      if String(Read(lValue, 1)) <> 'value' then
        raise new Exception('value second');
      var lList := new List<Integer>;
      lList.Add(12);
      if Integer(Read(lList, 0)) <> 12 then
        raise new Exception('ordinary indexer');
      for each lIndex in [-1, 2] do begin
        var lThrew := false;
        try
          Read(lPair, lIndex);
        except
          on IndexOutOfRangeException do lThrew := true;
        end;
        if not lThrew then
          raise new Exception('bounds');
      end;
      if FirstValue(Construct(typeOf(FirstValue), 3)).Value <> 3 then
        raise new Exception('constructor');
      if SecondValue(Construct(typeOf(SecondValue), 4)).Value <> 8 then
        raise new Exception('constructor type cache');
      if FirstValue(Construct(typeOf(FirstValue), 5)).Value <> 5 then
        raise new Exception('constructor repeat');
      Console.WriteLine('OK: dynamic tuple indexing');
    end;
  end;

end.
