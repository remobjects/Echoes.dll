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
  OxygeneUnaryBinder = public class(UnaryOperationBinder)
  private
  protected
  public
    constructor(aType: ExpressionType);
    method FallbackUnaryOperation(target: DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;

implementation

constructor OxygeneUnaryBinder(aType: ExpressionType);
begin
  inherited constructor(aType);
end;

method OxygeneUnaryBinder.FallbackUnaryOperation(target: DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  var lExpr := target.Expression;
  try
    if lExpr.Type <> target.LimitType then
      lExpr := Expression.Convert(lExpr, target.LimitType);
    case Operation of
      ExpressionType.Negate: lExpr := Expression.Negate(lExpr);
      ExpressionType.Not: lExpr := Expression.Not(lExpr);
      ExpressionType.OnesComplement: lExpr := Expression.OnesComplement(lExpr);
      ExpressionType.UnaryPlus: lExpr := Expression.UnaryPlus(lExpr);
    else
       raise new OxygeneBinderException(Resources.strInvalidOperator);
    end; // case
    if (lExpr.Type.IsValueType)  then
      lExpr := Expression.Convert(lExpr, typeOf(Object));
  except
    on e: Exception do begin
      lExpr := coalesce(errorSuggestion:Expression, Expression.Block(Expression.Throw(Expression.Constant(e)), Expression.Constant(nil, typeOf(Object))));
    end;
  end;

  exit new DynamicMetaObject(lExpr, OxygeneBinder.Restrict(nil, target));
end;

end.