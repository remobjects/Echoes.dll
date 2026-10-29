// Positive and negative guards for dynamic array reads/writes: direct values, fields, properties, rank, cache reuse and invalid indices.
namespace ArrayIndexTests;
uses System, System.Collections.Generic, RemObjects.Elements.Dynamic;
type
  Holder = public class
  public
    field Values: array of Integer := [10, 20];
    property Gets: Integer;
    property Items: array of Integer read begin Gets := Gets + 1; exit Values; end;
    property Callbacks: array of Func<Integer> read [() -> 42];
  end;
  Program = class
  public
    class method Read(aValue: dynamic; aIndex: dynamic): dynamic;
    begin
      exit aValue[aIndex];
    end;
    class method Write(aValue: dynamic; aIndex: dynamic; aItem: dynamic);
    begin
      aValue[aIndex] := aItem;
    end;
    class method Main;
    begin
      var lValues: array of Integer := [3, 4];
      if Integer(Read(lValues, 0)) <> 3 then
        raise new Exception('direct read');
      if Integer(Read(lValues, Int64(1))) <> 4 then
        raise new Exception('changing index type');
      Write(lValues, 1, 9);
      if lValues[1] <> 9 then
        raise new Exception('direct write');
      var lStrings: array of String := ['a', 'b'];
      if String(Read(lStrings, 0)) <> 'a' then
        raise new Exception('changing array type');
      Write(lStrings, 0, 'c');
      Write(lStrings, 1, nil);
      if (lStrings[0] <> 'c') or (lStrings[1] <> nil) then
        raise new Exception('reference writes');
      var lHolder := new Holder;
      var lDynamic: dynamic := lHolder;
      if Integer(lDynamic.Values[0]) <> 10 then
        raise new Exception('field read');
      lDynamic.Values[0] := 11;
      if Integer(lDynamic.Items[1]) <> 20 then
        raise new Exception('property read');
      lDynamic.Items[1] := 21;
      if (lHolder.Values[0] <> 11) or (lHolder.Values[1] <> 21) or (lHolder.Gets <> 2) then
        raise new Exception('property write/single evaluation');
      if Integer(lDynamic.Callbacks[0]()) <> 42 then
        raise new Exception('indexed callable');
      var lMatrix := new Integer[2, 3];
      var lMatrixDynamic: dynamic := lMatrix;
      lMatrixDynamic[1, 2] := 27;
      if Integer(lMatrixDynamic[1, 2]) <> 27 then
        raise new Exception('matrix');
      var lList := new List<Integer>(lValues);
      if Integer(Read(lList, 1)) <> 9 then
        raise new Exception('ordinary indexer');
      var lOther: array of Double := [2.5];
      if Double(Read(lOther, 0)) <> 2.5 then
        raise new Exception('array after default indexer');
      for each lIndex in [-1, 2] do begin
        var lRejected := false;
        try
          Read(lValues, lIndex);
        except
          on IndexOutOfRangeException do lRejected := true;
        end;
        if not lRejected then
          raise new Exception('bounds');
      end;
      var lInvalid := false;
      try
        Read(lValues, 'bad');
      except
        on OxygeneBinderException do lInvalid := true;
      end;
      if not lInvalid then
        raise new Exception('invalid index type');
      lInvalid := false;
      try
        Read(lMatrix, 0);
      except
        on OxygeneBinderException do lInvalid := true;
      end;
      if not lInvalid then
        raise new Exception('rank');
      Console.WriteLine('OK dynamic arrays');
    end;
  end;
end.
