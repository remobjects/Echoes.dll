namespace RemObjects.Elements.System;

type
  {$IF NOT NETCOREAPP}
  ArrayUtils = public static class
  public

    class method GetSubArray<T>(val: array of T; aStart, aLength: Integer): array of T;
    begin
      result := new T[aLength];
      for i := 0 to aLength-1 do
        result[i] := val[i+aStart];
    end;

    class method GetSubArray<T>(val: array of T; aRange: Range): array of T;
    begin
      var lLength := length(val);
      var lStart := aRange.fStart.GetOffset(lLength);
      var lEnd := aRange.fEnd.GetOffset(lLength);
      result := GetSubArray(val, lStart, lEnd-lStart);
    end;

  end;
  {$ENDIF}

end.