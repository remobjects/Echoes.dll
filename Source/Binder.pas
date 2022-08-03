namespace RemObjects.Elements.Dynamic;

interface

uses
  System.Dynamic,
  System.Linq,
  System.Runtime.CompilerServices,
  System.Linq.Expressions;

type
  OxygeneArgumentMode = public flags (
    None = 0,
    IsVar = 1,
    IsOut = 2
  );

  OxygeneArgument = public class
  private
    fMode: OxygeneArgumentMode;
  public
    constructor(aMode: OxygeneArgumentMode);
    property Mode: OxygeneArgumentMode read fMode;
  end;

  OxygeneBinderFlags = public flags (
    None = 0,
    ExplicitConversion = 1,
    StaticCall = 2,
    GetMember = 4,
    SetMember = 8,
    OptCall = 16
  );

  OxygeneBinderException = public class(Exception);

  OxygeneAmbigiousOverloadException = public class(Exception)
  private
    fOverloads: Array of System.Reflection.MethodBase;
  public
    constructor(aOverloads: Array of System.Reflection.MethodBase);
    method ToString: String; override;
  end;

  OxygeneBinder = public static class
  assembly
    class method Restrict(aPrev: BindingRestrictions; aNew: DynamicMetaObject): BindingRestrictions;
    class method IntConvert(aExpr: Expression; aCurrType, aType: &Type; aCheckCast: Boolean): Expression;
  public
    class method BinaryOperation(aFlags: OxygeneBinderFlags; aOperator: ExpressionType; aArg1, aArg2: OxygeneArgument): CallSiteBinder;
    class method UnaryOperation(aflags: OxygeneBinderFlags; aOperator: ExpressionType; aArg: OxygeneArgument): CallSiteBinder;
    class method Convert(aFlags: OxygeneBinderFlags; aTarget: &Type): CallSiteBinder;
    class method Invoke(aFlags: OxygeneBinderFlags; aArgs: array of OxygeneArgument): CallSiteBinder;
    // calls, or finds field or property;
    // name = null means default property (for get/set member)
    // name = null means ctor for staticcall without get/set
    // both instance and static call needs a "self" as the first parameter. (Static needs a System.Type instance)
    class method InvokeMember(aFlags: OxygeneBinderFlags; aName: String; aTypeArgs: Array of &Type;
      aArgs: Array of OxygeneArgument): CallSiteBinder;
  end;

implementation

class method OxygeneBinder.BinaryOperation(aFlags: OxygeneBinderFlags; aOperator: ExpressionType; aArg1, aArg2: OxygeneArgument): CallSiteBinder;
begin
  exit new OxygeneBinaryBinder(aOperator);
end;

class method OxygeneBinder.UnaryOperation(aflags: OxygeneBinderFlags; aOperator: ExpressionType; aArg: OxygeneArgument): CallSiteBinder;
begin
  exit new OxygeneUnaryBinder(aOperator);
end;

class method OxygeneBinder.Convert(aFlags: OxygeneBinderFlags; aTarget: &Type): CallSiteBinder;
begin
  exit new OxygeneConversionBinder(aTarget, OxygeneBinderFlags.ExplicitConversion in aFlags);
end;

class method OxygeneBinder.Invoke(aFlags: OxygeneBinderFlags; aArgs: array of OxygeneArgument): CallSiteBinder;
begin
  exit InvokeMember(OxygeneBinderFlags.None, '', nil, aArgs);
end;

class method OxygeneBinder.InvokeMember(aFlags: OxygeneBinderFlags; aName: String; aTypeArgs: Array of &Type;
      aArgs: Array of OxygeneArgument): CallSiteBinder;
begin
  if (OxygeneBinderFlags.SetMember in aFlags) then begin
    if (length(aArgs) = 1) then
      exit new OxygeneSetMemberBinder(aFlags, aName, length(aArgs), aTypeArgs)
    else
      exit new OxygeneSetIndexBinder(aFlags, aName, aArgs, aTypeArgs)
  end else if (OxygeneBinderFlags.GetMember in aFlags) then begin
    if (length(aArgs) = 0) then
      exit new OxygeneGetMemberBinder(aFlags, aName, length(aArgs), aTypeArgs)
    else
      exit new OxygeneGetIndexBinder(aFlags, aName, aArgs, aTypeArgs)
  end;
  exit new OxygeneInvokeMemberBinder(aFlags, aName, length(aArgs), aTypeArgs);
end;

class method OxygeneBinder.Restrict(aPrev: BindingRestrictions; aNew: DynamicMetaObject): BindingRestrictions;
begin
  result := coalesce(aPrev, BindingRestrictions.Empty).Merge(
    if aNew.HasValue and (aNew.Value = nil) then
      BindingRestrictions.GetInstanceRestriction(aNew.Expression, nil)
    else
      BindingRestrictions.GetTypeRestriction(aNew.Expression, aNew.LimitType)
  );
end;

class method OxygeneBinder.IntConvert(aExpr: Expression; aCurrType, aType: &Type; aCheckCast: Boolean): Expression;
begin
  if aCurrType = typeOf(Object) then exit Expression.Convert(Expression.Convert(aExpr, aCurrType), aType);
  if (aCurrType = typeOf(String)) and (&Type.GetTypeCode(aType) in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16,
    TypeCode.Int32, TypeCode.UInt32,  TypeCode.Int64, TypeCode.UInt64, TypeCode.Double, TypeCode.Single, TypeCode.Decimal]) then begin
    exit Expression.Call(aType.GetMethod('Parse', [typeOf(String)]), Expression.Convert(aExpr, typeOf(String)));
  end else if (aType = typeOf(String)) and (aCurrType <> aType) then begin
    if aCurrType = typeOf(Char) then
      exit Expression.New(typeOf(String).GetConstructor([typeOf(Char), typeOf(Integer)]), Expression.Convert(aExpr, typeOf(Char)), Expression.Constant(1))
    else
      exit Expression.Call(aExpr, typeOf(Object).GetMethod('ToString', []));
  end else begin
    if aCheckCast or (&Type.GetTypeCode(aType) in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16,
    TypeCode.Int32, TypeCode.UInt32,  TypeCode.Int64, TypeCode.UInt64, TypeCode.Double, TypeCode.Single, TypeCode.Decimal]) or
     (&Type.GetTypeCode(aCurrType) in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16,
    TypeCode.Int32, TypeCode.UInt32,  TypeCode.Int64, TypeCode.UInt64, TypeCode.Double, TypeCode.Single, TypeCode.Decimal]) then
    exit Expression.Convert(Expression.Convert(aExpr, aCurrType), iif(aType.IsByRef, aType.GetElementType(), aType));
      exit Expression.TypeAs(Expression.Convert(aExpr, aCurrType), iif(aType.IsByRef, aType.GetElementType(), aType));
  end;
end;

constructor OxygeneArgument(aMode: OxygeneArgumentMode);
begin
  fMode := aMode;
end;

constructor OxygeneAmbigiousOverloadException(aOverloads: Array of System.Reflection.MethodBase);
begin
  inherited constructor(RemObjects.Elements.Dynamic.Properties.Resources.strAmbigiousOverloadStr);
  fOverloads := aOverloads;
end;

method OxygeneAmbigiousOverloadException.ToString: String;
begin
  exit String.Format(RemObjects.Elements.Dynamic.Properties.Resources.strAmbigiousOverload, String.Join(',', fOverloads.Select(a -> a.ToString).ToArray));
end;

end.