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
  OxygeneConversionBinder = public class(ConvertBinder)
  private
  protected
  public
    method FallbackConvert(target: DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;

implementation

method OxygeneConversionBinder.FallbackConvert(target: DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  try
    exit new DynamicMetaObject(OxygeneBinder.IntConvert(target.Expression, target.LimitType, self.Type, false),
      OxygeneBinder.Restrict(nil, target));
  except
    on e: Exception do begin
      exit new DynamicMetaObject(
        coalesce(errorSuggestion:Expression, Expression.Block(Expression.Throw(Expression.Constant(e)), Expression.Constant(nil, typeOf(Object)))),
        OxygeneBinder.Restrict(nil, target));
    end;
  end;
end;

end.
