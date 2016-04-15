namespace RemObjects.Oxygene.Dynamic;

interface

uses
  RemObjects.Oxygene.Dynamic.Properties,
  System.Collections.Generic,
  System.Dynamic,
  System.Linq,
  System.Linq.Expressions,
  System.Text;

type
  OxygeneBinaryBinder = public class(BinaryOperationBinder)
  private
    method GetBestType(aLeft, aRight: &Type): &Type;
  protected
  public
    constructor(aType: ExpressionType);
    method FallbackBinaryOperation(target: DynamicMetaObject; arg: DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;

implementation

method OxygeneBinaryBinder.FallbackBinaryOperation(
  target: DynamicMetaObject; 
  arg: DynamicMetaObject; 
  errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  var lLeftExpr := target.Expression;
  try
    var lLeft := target.LimitType;
    var lRight := arg.LimitType;
    var lResType: &Type;
    var lWorkType: &Type := nil;
  
    case Operation of
      ExpressionType.TypeIs: 
        begin
          if arg.Value is &Type then begin
            exit new DynamicMetaObject(Expression.TypeIs(target.Expression, &Type(arg.Value)), 
              OxygeneBinder.Restrict(nil, target).Merge(BindingRestrictions.GetInstanceRestriction(arg.Expression, arg.Value)));
          end else 
            raise new OxygeneBinderException(Resources.strInvalidOperator); 
        end;
      ExpressionType.Add,
      ExpressionType.AddChecked: 
            if ((lLeft = typeOf(String)) or (lLeft = typeOf(Char))) and 
              ((lRight = typeOf(String)) or (lRight = typeOf(Char))) then
              lResType := typeOf(String)
            else if (lLeft = typeOf(String)) or
              (lRight = typeOf(String)) then
              lResType := typeOf(String)
            else
              lResType := GetBestType(lLeft, lRight);
      ExpressionType.GreaterThan,
      ExpressionType.GreaterThanOrEqual, 
      ExpressionType.LessThan,
      ExpressionType.LessThanOrEqual,
      ExpressionType.NotEqual,
      ExpressionType.Equal: begin
        lWorkType := GetBestType(lLeft, lRight);
        lResType := typeOf(Boolean);
      end;
      ExpressionType.Modulo,
      ExpressionType.LeftShift,
      ExpressionType.RightShift:
        begin
          if (&Type.GetTypeCode(lLeft) in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, 
            TypeCode.Int32, TypeCode.UInt32,  TypeCode.Int64, TypeCode.UInt64]) and 
              (&Type.GetTypeCode(lRight) in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, 
            TypeCode.Int32, TypeCode.UInt32,  TypeCode.Int64, TypeCode.UInt64]) then
            lResType := lLeft
          else
            exit new DynamicMetaObject(
              coalesce(errorSuggestion:Expression, 
              Expression.Block(
              Expression.Throw(Expression.New(typeOf(OxygeneBinderException).GetConstructor([typeOf(String)]), Expression.Constant(Resources.strInvalidOperands))),
              Expression.Constant(nil, typeOf(Object))))
          
            , OxygeneBinder.Restrict(OxygeneBinder.Restrict(nil, target), arg));
        end;
      ExpressionType.And,
      ExpressionType.AndAlso,
      ExpressionType.ExclusiveOr,
      ExpressionType.Or,
      ExpressionType.OrElse:
        begin
          if (&Type.GetTypeCode(lLeft) in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, 
            TypeCode.Int32, TypeCode.UInt32,  TypeCode.Int64, TypeCode.UInt64, TypeCode.Boolean]) and 
              (&Type.GetTypeCode(lRight) in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, 
            TypeCode.Int32, TypeCode.UInt32,  TypeCode.Int64, TypeCode.UInt64, TypeCode.Boolean]) then
            lResType := lLeft
          else
            exit new DynamicMetaObject(
              coalesce(errorSuggestion:Expression,Expression.Block(
              Expression.Throw(Expression.New(typeOf(OxygeneBinderException).GetConstructor([typeOf(String)]), Expression.Constant(Resources.strInvalidOperands))),
              Expression.Constant(nil, typeOf(Object))))
          
            , OxygeneBinder.Restrict(OxygeneBinder.Restrict(nil, target), arg));
        end;
      ExpressionType.Divide,
      ExpressionType.Multiply,
      ExpressionType.MultiplyChecked,
      ExpressionType.Subtract,
      ExpressionType.SubtractChecked:
        lResType := GetBestType(lLeft, lRight);
    else
      exit new DynamicMetaObject(
        coalesce(errorSuggestion:Expression, Expression.Block(
        Expression.Throw(Expression.New(typeOf(OxygeneBinderException).GetConstructor([typeOf(String)]), Expression.Constant(Resources.strInvalidOperator))),
        Expression.Constant(nil, typeOf(Object))))
          
      , OxygeneBinder.Restrict(OxygeneBinder.Restrict(nil, target), arg));
    end; // case
    if lResType = nil then begin
      exit new DynamicMetaObject(
        coalesce(errorSuggestion:Expression, Expression.Block(
        Expression.Throw(Expression.New(typeOf(OxygeneBinderException).GetConstructor([typeOf(String)]), Expression.Constant(Resources.strInvalidOperands))),
        Expression.Constant(nil, typeOf(Object))))
          
      , OxygeneBinder.Restrict(OxygeneBinder.Restrict(nil, target), arg));
    end;

    if lWorkType = nil then lWorkType := lResType;
    var lRightExpr := arg.Expression;
    if lLeftExpr.Type <> lWorkType then
      lLeftExpr := OxygeneBinder.IntConvert(lLeftExpr, lLeft, lWorkType);
    if lRightExpr.Type <> lWorkType then
      lRightExpr := OxygeneBinder.IntConvert(lRightExpr, lRight, lWorkType);
    case Operation of
      ExpressionType.Add,
      ExpressionType.AddChecked:
        if lWorkType = typeOf(String) then 
          lLeftExpr := Expression.Call(typeOf(String).GetMethod('Concat', [typeOf(String), typeOf(String)]), lLeftExpr, lRightExpr)
        else
          lLeftExpr := Expression.Add(lLeftExpr, lRightExpr);
      ExpressionType.GreaterThan: lLeftExpr := Expression.GreaterThan(lLeftExpr, lRightExpr);
      ExpressionType.GreaterThanOrEqual: lLeftExpr := Expression.GreaterThanOrEqual(lLeftExpr, lRightExpr);
      ExpressionType.LessThan: lLeftExpr := Expression.LessThan(lLeftExpr, lRightExpr);
      ExpressionType.LessThanOrEqual: lLeftExpr := Expression.LessThanOrEqual(lLeftExpr, lRightExpr);
      ExpressionType.NotEqual: lLeftExpr := Expression.NotEqual(lLeftExpr, lRightExpr);
      ExpressionType.Equal: lLeftExpr := Expression.Equal(lLeftExpr, lRightExpr);
      ExpressionType.Modulo: lLeftExpr := Expression.Modulo(lLeftExpr, lRightExpr);
      ExpressionType.LeftShift: lLeftExpr := Expression.LeftShift(lLeftExpr, lRightExpr);
      ExpressionType.RightShift: lLeftExpr := Expression.RightShift(lLeftExpr, lRightExpr);
      ExpressionType.And: lLeftExpr := Expression.And(lLeftExpr, lRightExpr);
      ExpressionType.AndAlso: lLeftExpr := Expression.AndAlso(lLeftExpr, lRightExpr);
      ExpressionType.ExclusiveOr: lLeftExpr := Expression.ExclusiveOr(lLeftExpr, lRightExpr);
      ExpressionType.Or: lLeftExpr := Expression.Or(lLeftExpr, lRightExpr);
      ExpressionType.OrElse: lLeftExpr := Expression.OrElse(lLeftExpr, lRightExpr);
      ExpressionType.Divide: lLeftExpr := Expression.Divide(lLeftExpr, lRightExpr);
      ExpressionType.Multiply,
      ExpressionType.MultiplyChecked: lLeftExpr := Expression.Multiply(lLeftExpr, lRightExpr);
      ExpressionType.Subtract,
      ExpressionType.SubtractChecked: lLeftExpr := Expression.Subtract(lLeftExpr, lRightExpr);
    else
      exit new DynamicMetaObject(
        coalesce(errorSuggestion:Expression, Expression.Block(
        Expression.Throw(Expression.New(typeOf(OxygeneBinderException).GetConstructor([typeOf(String)]), Expression.Constant(Resources.strInvalidOperator))),
        Expression.Constant(nil, typeOf(Object))))
          
      , OxygeneBinder.Restrict(OxygeneBinder.Restrict(nil, target), arg));
    end; // case
  except
     on e: Exception do begin
      lLeftExpr := coalesce(errorSuggestion:Expression, Expression.Block(Expression.Throw(Expression.Constant(e)), Expression.Constant(nil, typeOf(Object))));
    end;
  end;

  if (lLeftExpr.Type.IsValueType)  then
    lLeftExpr := Expression.Convert(lLeftExpr, typeOf(Object));
  exit new DynamicMetaObject(lLeftExpr, OxygeneBinder.Restrict(OxygeneBinder.Restrict(nil, target), arg));
end;

method OxygeneBinaryBinder.GetBestType(aLeft, aRight: &Type): &Type;
begin
  if aLeft.IsAssignableFrom(aRight) then exit aRight;
  if aRight.IsAssignableFrom(aLeft) then exit aLeft;

  var n1, n2: Integer;
  var lUnassigned: Boolean := false;
  case &Type.GetTypeCode(aLeft) of
    TypeCode.Double: n1 := 6;
    TypeCode.Single: n1 := 5;
    TypeCode.Byte: begin n1 := 1;lUnassigned := true; end;
    TypeCode.Int16: n1 := 2;
    TypeCode.Int32: n1 := 3;
    TypeCode.Int64: n1 := 4;
    TypeCode.SByte: n1 := 1;
    TypeCode.UInt16: begin n1 := 2;lUnassigned := true; end;
    TypeCode.UInt32: begin n1 := 3;lUnassigned := true; end;
    TypeCode.UInt64: begin n1 := 4; lUnassigned := true; end;
  else 
    exit nil;
  end; // case
  case &Type.GetTypeCode(aRight) of
    TypeCode.Double: n2 := 6;
    TypeCode.Single: n2 := 5;
    TypeCode.Byte: n2 := 1;
    TypeCode.Int16: begin n2 := 2; lUnassigned := false; end;
    TypeCode.Int32: begin n2 := 3; lUnassigned := false; end;
    TypeCode.Int64: begin n2 := 4; lUnassigned := false; end;
    TypeCode.SByte: begin n2 := 1; lUnassigned := false; end;
    TypeCode.UInt16: n2 := 2;
    TypeCode.UInt32: n2 := 3;
    TypeCode.UInt64: n2 := 4;
  else 
    exit nil;
  end; 
  case (if n1 > n2 then n1 else n2) of
    1: if lUnassigned then exit typeOf(Byte) else exit typeOf(SByte);
    2: if lUnassigned then exit typeOf(UInt16) else exit typeOf(Int16);
    3: if lUnassigned then exit typeOf(UInt32) else exit typeOf(Int32);
    4: if lUnassigned then exit typeOf(UInt64) else exit typeOf(Int64);
    5: exit typeOf(Single);
  else // 6
   exit typeOf(Double);
  end; // case
end;

constructor OxygeneBinaryBinder(aType: ExpressionType);
begin
  inherited constructor(aType);
end;

end.
