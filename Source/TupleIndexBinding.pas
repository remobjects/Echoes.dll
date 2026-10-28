namespace RemObjects.Elements.Dynamic;

uses
  System.Collections.Generic,
  System.Dynamic,
  System.Linq.Expressions;

type
  TupleIndexBinding = assembly static class
  private
    class method CollectItems(aType: &Type; aValue: Expression; aItems: List<Expression>): Boolean;
    begin
      if not aType.IsGenericType then
        exit false;
      var lCount := length(aType.GetGenericArguments);
      var lName := aType.GetGenericTypeDefinition.FullName;
      var lValueTuple := lName = 'System.ValueTuple`' + lCount;
      if (lCount < 1) or (lCount > 8) or
         (not lValueTuple and (lName <> 'System.Tuple`' + lCount)) then
        exit false;
      for i: Integer := 1 to Math.Min(lCount, 7) do
        aItems.Add(Expression.PropertyOrField(aValue, 'Item' + i));
      if lCount = 8 then begin
        var lRest := Expression.PropertyOrField(aValue, 'Rest');
        exit CollectItems(lRest.Type, lRest, aItems);
      end;
      exit true;
    end;

  assembly
    class method Bind(aTarget: DynamicMetaObject; aIndexes: array of DynamicMetaObject): DynamicMetaObject;
    begin
      if length(aIndexes) <> 1 then
        exit nil;
      var lIndex := aIndexes[0];
      if &Type.GetTypeCode(lIndex.LimitType) not in [TypeCode.SByte, TypeCode.Byte,
          TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.Int64] then
        exit nil;
      var lItems := new List<Expression>;
      if not CollectItems(aTarget.LimitType,
          Expression.Convert(aTarget.Expression, aTarget.LimitType), lItems) then
        exit nil;
      var lIndexExpression := Expression.Convert(
        Expression.Convert(lIndex.Expression, lIndex.LimitType), typeOf(Int64));
      var lCases := new List<SwitchCase>;
      for i: Integer := 0 to lItems.Count - 1 do
        lCases.Add(Expression.SwitchCase(Expression.Convert(lItems[i], typeOf(Object)),
          Expression.Constant(Int64(i))));
      var lFailure := Expression.Throw(Expression.New(typeOf(IndexOutOfRangeException)), typeOf(Object));
      var lRead := Expression.Switch(lIndexExpression, lFailure, lCases.ToArray);
      exit new DynamicMetaObject(lRead, OxygeneBinder.Restrict(
        OxygeneBinder.Restrict(nil, aTarget), lIndex));
    end;
  end;

end.
