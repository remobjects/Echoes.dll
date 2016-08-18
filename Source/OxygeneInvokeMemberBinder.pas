namespace RemObjects.Oxygene.Dynamic;

interface

uses
  RemObjects.Oxygene.Dynamic.Properties,
  System.Collections.Generic,
  System.Dynamic,
  System.Linq,
  System.Reflection,
  System.Linq.Expressions,
  System.Text;

type
  OxygeneInvokeMemberBinder = public class(InvokeMemberBinder)
  assembly
    fFlags: OxygeneBinderFlags;
    fTypeArgs: array of &Type;
    fName: String;
    class method GetPropertyAccessors(aType: &Type; aName: String; aStatic, aSet: Boolean): List<MethodBase>;
    class method Failure(target: DynamicMetaObject; args: array of DynamicMetaObject; errorSuggestion: DynamicMetaObject; msg: String): DynamicMetaObject;
    class method FindMatch(aTypeArgs: array of &Type; aPosibilities: List<MethodBase>; args: array of DynamicMetaObject): Tuple<MethodBase, array of Expression, Expression>;
    class method FixGen(aTypeArgs: array of &Type; aType: &Type): &Type;
    class method IsCompatibleParameterType(aSrc: &Type; aType: &Type): Boolean;
    class method GetImplicitOperator(aSrc, aDest: &Type): MethodInfo;
    class method BetterFunctionMember(aTypeArgs: array of &Type; &Params: array of DynamicMetaObject; aBest: MethodBase; aBestOffsets: array of Int32; aBestIsParams: Integer; aCurrent: MethodBase; aCurrentOffsets: array of Int32; aCurrentIsParams: Integer): Boolean;
    method EqualName(a: MemberInfo): Boolean;
    class method GetTypeDistance(aDest, aSrc: &Type): Integer;
    class method BetterConversionFromExpression(aExpr: DynamicMetaObject; aBestParam: &Type; aCurrentParam: &Type): Integer;
    class method IsMoreSpecific(lBestParam: &Type; lCurrentParam: &Type): Integer;
    class method IsNullable(aType: &Type): Boolean;
  protected
  public
    constructor(aFlags: OxygeneBinderFlags; aName: String; aCount: Integer; aTypeArgs: Array of &Type);
    
    method FallbackInvokeMember(target: System.Dynamic.DynamicMetaObject; args: array of System.Dynamic.DynamicMetaObject; errorSuggestion: System.Dynamic.DynamicMetaObject): System.Dynamic.DynamicMetaObject; override;
    method FallbackInvoke(target: System.Dynamic.DynamicMetaObject; args: array of System.Dynamic.DynamicMetaObject; errorSuggestion: System.Dynamic.DynamicMetaObject): System.Dynamic.DynamicMetaObject; override;
  end;

  OxygeneGetMemberBinder = public class(GetMemberBinder)
  private
    fFlags: OxygeneBinderFlags;
    fTypeArgs: array of &Type;
    fName: String;
  public
    constructor(aFlags: OxygeneBinderFlags; aName: String; aCount: Integer; aTypeArgs: Array of &Type);
    method FallbackGetMember(target, errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;

  OxygeneSetMemberBinder = public class(SetMemberBinder)
  private
    fFlags: OxygeneBinderFlags;
    fTypeArgs: array of &Type;
    fName: String;
  public
    constructor(aFlags: OxygeneBinderFlags; aName: String; aCount: Integer; aTypeArgs: Array of &Type);
    method FallbackSetMember(target, value, errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;
implementation

method OxygeneInvokeMemberBinder.FallbackInvoke(target: System.Dynamic.DynamicMetaObject; args: array of System.Dynamic.DynamicMetaObject; errorSuggestion: System.Dynamic.DynamicMetaObject): System.Dynamic.DynamicMetaObject;
begin
  exit FallbackInvokeMember(target, args, errorSuggestion);
end;

method OxygeneInvokeMemberBinder.FallbackInvokeMember(target: System.Dynamic.DynamicMetaObject; args: array of System.Dynamic.DynamicMetaObject; errorSuggestion: System.Dynamic.DynamicMetaObject): System.Dynamic.DynamicMetaObject;
begin
  var lStatic := OxygeneBinderFlags.StaticCall in fFlags;
  fName := Name;
  var lPosibilities: List<MethodBase>;
  var lRestrict := OxygeneBinder.Restrict(nil, target);
  for i: Integer := 0 to length(args) -1 do
    lRestrict := OxygeneBinder.Restrict(lRestrict, args[i]);
  if lStatic then begin
    var lType := target.Value as &Type;
    if ((OxygeneBinderFlags.GetMember in fFlags) or (OxygeneBinderFlags.SetMember in fFlags)) then begin
      if String.IsNullOrEmpty(fName) then begin
        var lDefault := array of DefaultMemberAttribute(lType.GetCustomAttributes(typeOf(DefaultMemberAttribute), true)).FirstOrDefault;
        if lDefault = nil then raise new OxygeneBinderException(Resources.strNoDefaultProperty);
        fName := lDefault.MemberName;
      end;
      var lField := lType.GetField(Name, BindingFlags.Static or BindingFlags.Public or BindingFlags.IgnoreCase);
      if (length(args) = iif(OxygeneBinderFlags.GetMember in fFlags, 0, 1)) and (lField <> nil) then begin
        
        var lExpr: Expression;
         if OxygeneBinderFlags.GetMember in fFlags then
           lExpr := Expression.Field(nil, lField)
         else
           lExpr := Expression.Assign(Expression.Field(nil, lField),  OxygeneBinder.IntConvert(args[0].Expression, args[0].LimitType, lField.FieldType));
        if (lExpr.Type.IsValueType)  then
          lExpr := Expression.Convert(lExpr, typeOf(Object));
        exit new DynamicMetaObject(lExpr, lRestrict);
      end;

      lPosibilities := GetPropertyAccessors(lType, fName, true,  OxygeneBinderFlags.SetMember in fFlags);
      if (OxygeneBinderFlags.GetMember in fFlags) and (lPosibilities = nil)and (length(args) = 0) then begin
        var lPos := lType.GetMethods(BindingFlags.Public or BindingFlags.Static);
        if lPos <> nil then lPos := lPos.Where(@EqualName).ToArray;
        if length(lPos) = 0 then exit Failure(target, args, errorSuggestion, String.Format(Resources.strNoPropertiesByThatName, fName, lType));
        lPosibilities := new List<MethodBase>();
        for each el in lPos do 
          lPosibilities.Add(el);
      end;

      if lPosibilities = nil then
        exit Failure(target, args, errorSuggestion, String.Format(Resources.strNoPropertiesByThatName, fName, lType));
    end else 
    if String.IsNullOrEmpty(fName) then begin
      var lPos := lType.GetConstructors(BindingFlags.Public or BindingFlags.Instance);
      if length(lPos) = 0 then exit Failure(target, args, errorSuggestion, Resources.strNoConstructors);
      lPosibilities := new List<MethodBase>();
      for each el in lPos do 
        lPosibilities.Add(el);
    end else begin
      var lPos := lType.GetMethods(BindingFlags.Public or BindingFlags.Static);
      if lPos <> nil then lPos := lPos.Where(@EqualName).ToArray;
      if length(lPos) = 0 then exit Failure(target, args, errorSuggestion, String.Format(Resources.strNoMethodsByThatName, fName, lType));
      lPosibilities := new List<MethodBase>();
      for each el in lPos do 
        lPosibilities.Add(el);
    end;
  end else begin
    var lType := target.LimitType;
    if ((OxygeneBinderFlags.GetMember in fFlags) or (OxygeneBinderFlags.SetMember in fFlags)) then begin
      if String.IsNullOrEmpty(fName) then begin
        var lDefault := array of DefaultMemberAttribute(lType.GetCustomAttributes(typeOf(DefaultMemberAttribute), true)).FirstOrDefault;
        if lDefault = nil then exit Failure(target, args, errorSuggestion, Resources.strNoDefaultProperty);
        fName := lDefault.MemberName;
      end;

      var lField := lType.GetField(Name, BindingFlags.Instance or BindingFlags.Static or BindingFlags.Public or BindingFlags.IgnoreCase);
      if (length(args) = iif(OxygeneBinderFlags.GetMember in fFlags, 0, 1)) and (lField <> nil) then begin
        
        var lExpr: Expression;
         if OxygeneBinderFlags.GetMember in fFlags then
           lExpr := Expression.Field(Expression.Convert(target.Expression, target.LimitType), lField)
         else
           lExpr := Expression.Assign(Expression.Field(Expression.Convert(target.Expression, target.LimitType), lField),  OxygeneBinder.IntConvert(args[0].Expression, args[0].LimitType, lField.FieldType));
        if (lExpr.Type.IsValueType)  then
          lExpr := Expression.Convert(lExpr, typeOf(Object));
        exit new DynamicMetaObject(lExpr, lRestrict);
      end;

      lPosibilities := GetPropertyAccessors(lType, fName, false, OxygeneBinderFlags.SetMember in fFlags);
      if (OxygeneBinderFlags.GetMember in fFlags) and (lPosibilities = nil) and (length(args) = 0) then begin
        var lPos := lType.GetMethods(BindingFlags.Public or BindingFlags.Instance or BindingFlags.Static);
        if lPos <> nil then lPos := lPos.Where(@EqualName).ToArray;
        if length(lPos) = 0 then exit Failure(target, args, errorSuggestion, String.Format(Resources.strNoPropertiesByThatName, fName, lType));
        lPosibilities := new List<MethodBase>();
        for each el in lPos do 
          lPosibilities.Add(el);
      end;
      if lPosibilities = nil then
        exit Failure(target, args, errorSuggestion, String.Format(Resources.strNoPropertiesByThatName, fName, lType));
    end else begin
      if String.IsNullOrEmpty(fName) then begin
        if typeOf(&Delegate).IsAssignableFrom(lType) then
          fName := 'Invoke'
        else 
          raise new OxygeneBinderException(String.Format(Resources.strCannotInvokeNonDelegate, lType));
      end;
      var lPos := lType.GetMethods(BindingFlags.Public or BindingFlags.NonPublic or BindingFlags.Instance or BindingFlags.Static);
      if lPos <> nil then lPos := lPos.Where(@EqualName).ToArray;
      if length(lPos) = 0 then begin 
        if OxygeneBinderFlags.OptCall in fFlags then
          exit new DynamicMetaObject(Expression.Constant(nil, typeOf(Object)), lRestrict);
        exit Failure(target, args, errorSuggestion, String.Format(Resources.strNoMethodsByThatName, fName, lType));
      end;
        lPosibilities := new List<MethodBase>();
        for each el in lPos do 
          lPosibilities.Add(el);
    end;
  end;
  // calls, or finds field or property; 
  // name = null means default property (for get/set member)
  // name = null means ctor for staticcall without get/set
  // both instance and static call needs a "self" as the first parameter. (Static needs a System.Type instance)
  var lExpr: Expression;

  var lMatch := FindMatch(fTypeArgs, lPosibilities, args);
  if lMatch = nil then begin
    exit Failure(target, args, errorSuggestion, Resources.strNoOverloadWithTheseParameters);
  end;
  if lMatch.Item3 <> nil then 
    lExpr := lMatch.Item3
  else 
  try
    if lMatch.Item1 is ConstructorInfo then
      lExpr := Expression.New(ConstructorInfo(lMatch.Item1), lMatch.Item2)
    else if lStatic or lMatch.Item1.IsStatic then
      lExpr := Expression.Call(MethodInfo(lMatch.Item1), lMatch.Item2)
    else begin
      lExpr := Expression.Call(Expression.Convert(target.Expression, target.LimitType), MethodInfo(lMatch.Item1), lMatch.Item2);
    end;

    if (lExpr.Type = nil) or (lExpr.Type = typeOf(Void)) then
      lExpr := Expression.Block(lExpr, Expression.Constant(nil, typeOf(Object)));
  except
    on e: Exception do begin
      lExpr := Expression.Block(Expression.Throw(Expression.Constant(e)), Expression.Constant(nil, typeOf(Object)));
    end;
  end;
  if (lExpr.Type.IsValueType)  then
    lExpr := Expression.Convert(lExpr, typeOf(Object));
  exit new DynamicMetaObject(lExpr, lRestrict);
end;

constructor OxygeneInvokeMemberBinder(aFlags: OxygeneBinderFlags; aName: String; aCount: Integer; aTypeArgs: Array of &Type);
begin
  inherited constructor(aName, true, new CallInfo(aCount));
  fFlags := aFlags;
  fTypeArgs := aTypeArgs;
end;

class method OxygeneInvokeMemberBinder.GetPropertyAccessors(aType: &Type; aName: String; aStatic, aSet: Boolean): List<MethodBase>;
begin
  var lProperties := aType.GetProperties((if aStatic then BindingFlags.Static else BindingFlags.Instance) or BindingFlags.Public or BindingFlags.FlattenHierarchy);
  if lProperties <> nil then lProperties := lProperties.Where(a->a.Name.ToLower = aName.ToLower).ToArray;
  if length(lProperties) = 0 then exit nil;
  result := new List<MethodBase>();
  for each el in lProperties do begin
    var lMeth := if aSet then el.GetSetMethod(false) else el.GetGetMethod(false);
    if lMeth <> nil then result.Add(lMeth);
  end;
end;

class method OxygeneInvokeMemberBinder.Failure(target: DynamicMetaObject; args: array of DynamicMetaObject; errorSuggestion: DynamicMetaObject; msg: String): DynamicMetaObject;
begin
  var lRestrict := OxygeneBinder.Restrict(nil, target);
  for i: Integer := 0 to length(args) -1 do
    lRestrict := OxygeneBinder.Restrict(lRestrict, args[i]);
  exit new DynamicMetaObject(coalesce(errorSuggestion:Expression, 
    Expression.Block(
        Expression.Throw(Expression.New(typeOf(OxygeneBinderException).GetConstructor([typeOf(String)]), Expression.Constant(msg))),
        Expression.Constant(nil, typeOf(Object)))), lRestrict);
end;


class method OxygeneInvokeMemberBinder.FindMatch(aTypeArgs: array of &Type; aPosibilities: List<MethodBase>; args: array of DynamicMetaObject): Tuple<MethodBase, array of Expression, Expression>;
begin
  // first; if we have GetPars; throw everything away that doesn't make sense.
  if length(aTypeArgs) > 0 then begin
    for i: Integer := aPosibilities.Count -1 downto 0 do begin
      if length(aPosibilities[i].GetGenericArguments) <> length(aTypeArgs) then begin
        aPosibilities.RemoveAt(i);
      end;
    end;
  end;
  var lOffsets: array of array of Integer := new array of Int32[aPosibilities.Count];
  var lParamsParameterOffset: Array of Integer := new Int32[aPosibilities.Count];
  var lCurrOffsets: Array of Integer;
  // check and eliminate all non-matching parameters.
  for i: Integer := 0 to aPosibilities.Count -1 do begin
    lParamsParameterOffset[i] := -1;
    var lPars := aPosibilities[i].GetParameters;
    var lCount := lPars.Length;
    var lDef: Integer := 0;
    var lHasParamsArray: Boolean := false;
    for j: Integer := 0 to lCount -1 do begin
      if ParameterAttributes.HasDefault in lPars[j].Attributes  then inc(lDef);
      if ParameterAttributes.Optional in lPars[j].Attributes  then inc(lDef);
    end;
    //for j: Integer := 0 to lCount -1 do if ParameterAttributes.HasDefault in lPars[j].Attributes  then inc(lDef);
    if (lCount = 0) or (length(lPars[lCount-1].GetCustomAttributes(typeOf(ParamArrayAttribute), false)) = 0) then begin
      if (args.Length < lCount - lDef) or (args.Length > lCount) then continue;
      lHasParamsArray := false;
    end else 
     lHasParamsArray := true;
    lCurrOffsets := new Integer[args.Length];
    var lCurrParO := 0;
    var lUsesArrayParam: Boolean := false;
    for parI: Integer := 0 to args.Length -1 do begin
      var lOk := false;
      while lCurrParO < lCount do begin
        var lPar := lPars[lCurrParO];
        var lParType := FixGen(aTypeArgs,lPar.ParameterType);
        if (lParType.IsByRef) then begin
          lParType := lParType.GetElementType();
        end;
        if not lUsesArrayParam and not ((lCurrParO = lCount -1) and (lHasParamsArray) and (parI < args.Length -1)) then begin
          if IsCompatibleParameterType(args[parI].LimitType, lParType) then begin
            lOk := true;
            lCurrOffsets[parI] := lCurrParO;
            inc(lCurrParO);
            break;
          end;
        end;
        if lParType.IsArray and lHasParamsArray and (lCurrParO = lCount -1) and  IsCompatibleParameterType(args[parI].LimitType, lParType.GetElementType) then begin
          lOk := true;
          lCurrOffsets[parI] := lCurrParO;
          lUsesArrayParam := true;
          if lParamsParameterOffset[i] = -1 then lParamsParameterOffset[i] := parI;
          break;
        end;
        if ParameterAttributes.HasDefault in lPar.Attributes then begin
          inc(lCurrParO);
          lOk := true;
          break;
        end else break;
      end;

      if not lOk then begin
        lCurrParO := -1;
        break;
      end;
    end;
    if lCurrParO = -1 then continue;
    lOffsets[i] := lCurrOffsets;
  end;
  var lResNo: Integer := -1;
  //
  // We might or might not have a "perfect match, now we need to compare them to see which is the best of them all for the given parameters.
  //
  for i: Integer := 0 to aPosibilities.Count -1 do begin
    if lOffsets[i] = nil then continue;
    if lResNo = -1 then begin
      lResNo := i;
      continue;
    end;
      // now we compare the lBestOverload with the current overload, if it's better set lBestOverload to current, else keep it
      // set the loser's allrlist[i] to null; BetterFunctionMember returns true if the candiate is better than the better
      if BetterFunctionMember(aTypeArgs, args,
            aPosibilities[lResNo], lOffsets[lResNo], lParamsParameterOffset[lResNo],
            aPosibilities[i], lOffsets[i], lParamsParameterOffset[i]) then lResNo := i;
  end;
  // 
  // We have found a best match, however we need to makes sure it's better than all the rest
  //
  var lAmbig: List<MethodBase> := nil;
  for i: Integer := 0 to aPosibilities.Count -1 do begin
    if (lOffsets[i] = nil) or (i = lResNo) then continue;
    if not BetterFunctionMember(aTypeArgs, args,
      aPosibilities[i], lOffsets[i], lParamsParameterOffset[i],
      aPosibilities[lResNo], lOffsets[lResNo], lParamsParameterOffset[lResNo]) then begin
      if lAmbig = nil then begin
        lAmbig := new List<MethodBase>();
        lAmbig.Add(aPosibilities[lResNo]);
      end;
      lAmbig.Add(aPosibilities[i]);
    end;
  end;
  if lAmbig <> nil then begin
    exit new Tuple<MethodBase,array of Expression,Expression>(nil, nil, 
      Expression.Block(
        Expression.Throw(Expression.New(typeOf(OxygeneAmbigiousOverloadException).GetConstructor([typeOf(array of MethodBase)]), Expression.Constant(lAmbig.ToArray))),
        Expression.Constant(nil, typeOf(Object))));
  end;
  if lResNo = -1 then exit nil;
  var lArrayParams: List<Expression> := nil;
  var lCurrent := aPosibilities[lResNo];
  var lPars := lCurrent.GetParameters;
  var lRes := new Expression[lPars.Length];
  lCurrOffsets := lOffsets[lResNo];
  for i: Integer := 0 to args.Length -1 do begin
    var lExpr := args[i].Expression;
    if (lParamsParameterOffset[lResNo] <> -1) and (i >= lParamsParameterOffset[lResNo]) then begin
      lExpr := OxygeneBinder.IntConvert(lExpr, args[i].LimitType, lPars[lPars.Length-1].ParameterType.GetElementType);
      if lArrayParams = nil then lArrayParams := new List<Expression>;
      lArrayParams.Add(lExpr);
    end else begin
      lExpr := OxygeneBinder.IntConvert(lExpr, args[i].LimitType, lPars[lCurrOffsets[i]].ParameterType);
      lRes[lCurrOffsets[i]] := lExpr;
    end;
  end;
  if lArrayParams <> nil then begin
     lRes[lRes.Length-1] := Expression.NewArrayInit(lPars[lPars.Length-1].ParameterType.GetElementType, lArrayParams);
  end;
  for i: Integer := 0 to lRes.Length -1 do begin
    if (lPars[i].IsOptional) then begin
      if assigned(lPars[i].ParameterType.GetElementType()) then
        lRes[i] := Expression.Constant(lPars[i].{$IFDEF PCL}DefaultValue{$ELSE}RawDefaultValue{$ENDIF}, lPars[i].ParameterType.GetElementType())
    end;
    if lRes[i] = nil then begin
      lRes[i] := Expression.Constant(lPars[i].{$IFDEF PCL}DefaultValue{$ELSE}RawDefaultValue{$ENDIF}, lPars[i].ParameterType);
    end;
  end;
  exit new Tuple<MethodBase,array of Expression,Expression>(lCurrent, lRes, nil);
end;

class method OxygeneInvokeMemberBinder.FixGen(aTypeArgs: array of &Type; aType: &Type): &Type;
begin
  if aType = nil then exit nil;
  if aType.IsGenericParameter then begin
    var lOffs := aType.GenericParameterPosition;
    if lOffs < length(aTypeArgs) then
      exit aTypeArgs[lOffs];
  end;
  exit aType;
end;

class method OxygeneInvokeMemberBinder.IsCompatibleParameterType(aSrc: &Type; aType: &Type): Boolean;
begin
  if aType = nil then exit false;
  var lSrcT := &Type.GetTypeCode(aSrc);
  var lDestT := &Type.GetTypeCode(aType);
  if lDestT in [TypeCode.Single, TypeCode.Double] then begin
    if lSrcT in [TypeCode.Single, TypeCode.Double, TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.UInt64, TypeCode.Int64] then
      exit true;
  end;
  if lDestT in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.UInt64, TypeCode.Int64] then
    if lSrcT in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.UInt64, TypeCode.Int64] then
      exit true;
  if lSrcT in [TypeCode.Char, TypeCode.String] then
    if lDestT = TypeCode.String then exit true;
  if aType.IsAssignableFrom(aSrc) then exit true;
  if GetImplicitOperator(aSrc, aType) <> nil then exit true;
  exit false;
end;

class method OxygeneInvokeMemberBinder.BetterFunctionMember(aTypeArgs: array of &Type; &Params: array of DynamicMetaObject; aBest: MethodBase; aBestOffsets: array of Int32; aBestIsParams: Integer; aCurrent: MethodBase; aCurrentOffsets: array of Int32; aCurrentIsParams: Integer): Boolean;
begin
  var lAtLeastOneBetterConversion: System.Boolean := false;
  var lHadNumberParameter: System.Boolean := false;
  var lDistBest: System.Int32 := 0;
  var lDistCurr: System.Int32 := 0;
  var lBestParams := aBest.GetParameters;
  var lCurrentParams := aCurrent.GetParameters;

  for i: Integer := 0 to &Params.Count -1 do begin 
    var lBestParam: &Type := FixGen(aTypeArgs, lBestParams[aBestOffsets[i]].ParameterType);
    if (aBestIsParams = aBestOffsets[i]) then        
      lBestParam := lBestParam.GetElementType;
    var lCurrentParam: &Type := FixGen(aTypeArgs, lCurrentParams[aCurrentOffsets[i]].ParameterType);
    if (aCurrentIsParams = aCurrentOffsets[i]) then        
      lCurrentParam := lCurrentParam.GetElementType;
    if lBestParam.Equals(lCurrentParam) then        
      continue; // no point
    if (((lBestParam <> nil) and (lCurrentParam <> nil)) and (
      &Type.GetTypeCode(lBestParam) in [TypeCode.Single, TypeCode.Double, TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.UInt64, TypeCode.Int64])
      and (&Type.GetTypeCode(lCurrentParam) in [TypeCode.Single, TypeCode.Double, TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.UInt64, TypeCode.Int64])) then begin
      var lTmp: &Type := &Params[i].LimitType;
      if (lTmp <> nil) and (&Type.GetTypeCode(lTmp) in [TypeCode.Single, TypeCode.Double, TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.UInt64, TypeCode.Int64]) then begin
        lHadNumberParameter := true;
        lDistBest := lDistBest + GetTypeDistance(lBestParam, lTmp);
        lDistCurr := lDistCurr + GetTypeDistance(lCurrentParam, lTmp);
        continue;
      end
    end;
    case BetterConversionFromExpression(&Params[i], lBestParam, lCurrentParam) of 
      1: exit false; // lBestParam is better than lCurrentParam; exit as it wouldn't mean lCurrentParam CAN be better than lBestParam
      -1:  lAtLeastOneBetterConversion := true; // lCurrentParam is better than lBestParam 
      // case 0: they're equal in conversion
    end;
  end;
  if lAtLeastOneBetterConversion then  
    exit true;
  if (lHadNumberParameter) and (lDistBest <> lDistCurr) then begin
    if lDistBest > lDistCurr then    
      exit true
    else    
      exit false
  end;
  // non-generic should be better than generic
  if (length(aBest.GetGenericArguments) <> 0) and (length(aCurrent.GetGenericArguments) = 0) then  exit true;
  if (length(aBest.GetGenericArguments) = 0) and (length(aCurrent.GetGenericArguments) <> 0) then// exit if the reverse is true
    exit false;

  // non-params should be better than params
  if (aBestIsParams <> -1) and (aCurrentIsParams = -1) then  exit true;
  if (aBestIsParams = -1) and (aCurrentIsParams <> -1) then// exit if the reverse is true
    exit false;

  // now the one with the least parameters should be the chosen one
  if lBestParams.Length > lCurrentParams.Length then  exit true;
  if lBestParams.Length < lCurrentParams.Length then// once again, exit if the reverse is true
    exit false;

  // last resort: An instance method should be prefered over a static one
  if (aBest.IsStatic) and (not aCurrent.IsStatic) then  exit true;
  if (not aBest.IsStatic) and (aCurrent.IsStatic) then  exit false;

  // now we got to use the original param types (ie not resolved) and check which parameter is more or less specific
  for i: Integer := 0 to &Params.Count -1 do begin 
      var lBetterParam: &Type := lBestParams[aBestOffsets[i]].ParameterType;
      var lCurrentParam: &Type := lCurrentParams[aCurrentOffsets[i]].ParameterType;

      case IsMoreSpecific(lBetterParam, lCurrentParam) of 
        1: exit false; // return false again as lBetterParam is more specific
        -1: lAtLeastOneBetterConversion := true; // there's at least 1 better conversion
          
      end;
    end;
  result := lAtLeastOneBetterConversion;
end;

class method OxygeneInvokeMemberBinder.GetTypeDistance(aDest, aSrc: &Type): Integer;
begin
  var n1, n2: Integer;
  var lUnassigned1: Boolean := false;
  var lUnassigned2: Boolean := false;
  case &Type.GetTypeCode(aDest) of
    TypeCode.Double: n1 := 6;
    TypeCode.Single: n1 := 5;
    TypeCode.Int16: n1 := 2;
    TypeCode.Int32: n1 := 3;
    TypeCode.Int64: n1 := 4;
    TypeCode.SByte: n1 := 1;
    TypeCode.Byte: begin n1 := 1;lUnassigned1 := true; end;
    TypeCode.UInt16: begin n1 := 2;lUnassigned1 := true; end;
    TypeCode.UInt32: begin n1 := 3;lUnassigned1 := true; end;
    TypeCode.UInt64: begin n1 := 4; lUnassigned1 := true; end;
  else 
    exit 1000;
  end; // case
  case &Type.GetTypeCode(aSrc) of
    TypeCode.Double: n2 := 6;
    TypeCode.Single: n2 := 5;
    TypeCode.Int16: n2 := 2;
    TypeCode.Int32: n2 := 3;
    TypeCode.Int64: n2 := 4;
    TypeCode.SByte: n2 := 1;
    TypeCode.Byte: begin n2 := 1;lUnassigned2 := true; end;
    TypeCode.UInt16: begin n2 := 2;lUnassigned2 := true; end;
    TypeCode.UInt32: begin n2 := 3;lUnassigned2 := true; end;
    TypeCode.UInt64: begin n2 := 4; lUnassigned2 := true; end;
  else 
    exit 1000;
  end; 
  var lOrd := n1 - n2;
  if lOrd < 0 then lOrd := -lOrd + 4;
  if lUnassigned1 <> lUnassigned2 then lOrd := lOrd + 4;
  exit lOrd;
end;

class method OxygeneInvokeMemberBinder.BetterConversionFromExpression(aExpr: DynamicMetaObject; aBestParam: &Type; aCurrentParam: &Type): Integer;
begin
  if aBestParam.Equals(aCurrentParam) then// same type; saves time
  exit 0;

  var aType: &Type := aExpr.LimitType;

  if (aType = typeOf(Object)) and (aExpr.Value = nil) then begin
    if (((aBestParam.IsValueType) and (not IsNullable(aBestParam)))) and (not ((aCurrentParam.IsValueType) and (not IsNullable(aCurrentParam)))) then    exit -1;
    if (not ((aBestParam.IsValueType) and (not IsNullable(aBestParam)))) and (((aCurrentParam.IsValueType) and (not IsNullable(aCurrentParam)))) then    exit 1;
    exit 0
  end;
  if aType = nil then  exit 0;
  // if they match the type, they're a better match

  if aType.Equals(aBestParam) then  exit 1;
  if aType.Equals(aCurrentParam) then  exit -1;

  // if there is an implicit conversion from aBestParam to aCurrentParam, but not the other way around, it's a better one
  if (IsCompatibleParameterType(aBestParam, aCurrentParam)) and (not IsCompatibleParameterType(aCurrentParam, aBestParam)) then  exit 1;

  // if there is an implicit conversion from aCurrentParam to aBestParam, but not the other way around, it's a better one
  if (IsCompatibleParameterType(aCurrentParam, aBestParam)) and (not IsCompatibleParameterType(aBestParam, aCurrentParam)) then  exit -1;

  // now we need to check what number is a better match, if any
  if  &Type.GetTypeCode(aType) in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.UInt64, TypeCode.Int64]  then begin // it's an integer begin
    if (&Type.GetTypeCode(aBestParam) in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.UInt64, TypeCode.Int64]) and (&Type.GetTypeCode(aCurrentParam) not in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.UInt64, TypeCode.Int64]) then    exit 1;
    if (&Type.GetTypeCode(aBestParam) not in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.UInt64, TypeCode.Int64]) and (&Type.GetTypeCode(aCurrentParam) in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.UInt64, TypeCode.Int64]) then    exit -1;
    if (&Type.GetTypeCode(aBestParam) in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.UInt64, TypeCode.Int64])  and (&Type.GetTypeCode(aCurrentParam) in [TypeCode.Byte, TypeCode.SByte, TypeCode.Int16, TypeCode.UInt16, TypeCode.Int32, TypeCode.UInt32, TypeCode.UInt64, TypeCode.Int64]) then begin
      // return the best matching integer overload
      var aBestOrd := GetTypeDistance(aBestParam, aType);
      var aCurrentOrd := GetTypeDistance(aCurrentParam, aType);
      if aBestOrd < aCurrentOrd then      exit 1;
      if aBestOrd > aCurrentOrd then      exit -1
    end

  end;
  // if there is an implicit conversion from aBestParam to aCurrentParam, but not the other way around, it's a better one
  if (IsCompatibleParameterType(aType, aBestParam)) and (not IsCompatibleParameterType(aType, aCurrentParam)) then  exit 1;

  // if there is an implicit conversion from aCurrentParam to aBestParam, but not the other way around, it's a better one
  if (IsCompatibleParameterType(aType, aCurrentParam)) and (not IsCompatibleParameterType(aType, aBestParam)) then  exit -1;

  exit 0
end;

class method OxygeneInvokeMemberBinder.IsMoreSpecific(lBestParam: &Type; lCurrentParam: &Type): Integer;
begin
  if lBestParam = nil then  exit 0;
  if lCurrentParam = nil then  exit 0;

  if (typeOf(&Delegate).IsAssignableFrom(lBestParam)) and (typeOf(&Delegate).IsAssignableFrom(lCurrentParam)) then begin
    var lBest := lBestParam.GetMethod('Invoke');
    var lCurr:= lCurrentParam.GetMethod('Invoke');
    if (lBest <> nil) and (lCurr <> nil) then begin
      if length(lBest.GetParameters) < length(lCurr.GetParameters) then      exit 1;
      if length(lBest.GetParameters) > length(lCurr.GetParameters) then      exit -1
    end
  end;
  // if current is not a generic parameter, that one is more specific

  if lBestParam.IsGenericType and  lCurrentParam. IsGenericType then begin
    var lBestArgs := lBestParam.GetGenericArguments;
    var lCurrentArgs := lCurrentParam.GetGenericArguments;
    if length(lBestArgs) = length(lCurrentArgs)  then begin
      var lMoreSpecific: System.Int32 := 0;
      for I: Integer := length(lBestArgs) -1 downto 0 do begin
        case IsMoreSpecific(lBestArgs[I], lCurrentArgs[I]) of 
          1:  if lMoreSpecific >= 0 then lMoreSpecific := 1 else exit 0;
         -1:  if lMoreSpecific <= 0 then lMoreSpecific := -1 else exit 0;
        end;
        exit lMoreSpecific;
      end;
    end;
  end;
  if lBestParam.IsArray and lCurrentParam.IsArray then 
    exit IsMoreSpecific(lBestParam.GetElementType, lCurrentParam.GetElementType);
  exit 0;
end;

class method OxygeneInvokeMemberBinder.IsNullable(aType: &Type): Boolean;
begin
  exit (aType.IsGenericType) and (aType.GetGenericTypeDefinition = typeOf(&Nullable<1>));
end;

method OxygeneInvokeMemberBinder.EqualName(a: MemberInfo): Boolean;
begin
  exit String.Equals(a.Name, fName, StringComparison.OrdinalIgnoreCase);
end;

class method OxygeneInvokeMemberBinder.GetImplicitOperator(aSrc: &Type; aDest: &Type): MethodInfo;
begin
  for each item in Enumerable.Concat(aSrc.GetMethods(BindingFlags.Static or BindingFlags.Public), aDest.GetMethods(BindingFlags.Static or BindingFlags.Public)) do begin
    if item.Name <> 'op_Implicit' then continue;
    if (item.GetParameters().FirstOrDefault():ParameterType = aSrc) and (item.ReturnType = aDest) then exit item;
  end;
  exit nil;
end;

constructor OxygeneGetMemberBinder(aFlags: OxygeneBinderFlags; aName: String; aCount: Integer; aTypeArgs: Array of &Type);
begin
  inherited constructor(aName, true);
  fFlags := aFlags;
  fTypeArgs := aTypeArgs;
end;

method OxygeneGetMemberBinder.FallbackGetMember(target, errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  var lStatic := OxygeneBinderFlags.StaticCall in fFlags;
  var lPosibilities: List<MethodBase>;
  fName := Name;
  var lRestrict := OxygeneBinder.Restrict(nil, target);
  if lStatic then begin
    var lType := target.Value as &Type;
    if String.IsNullOrEmpty(fName) then begin
      var lDefault := array of DefaultMemberAttribute(lType.GetCustomAttributes(typeOf(DefaultMemberAttribute), true)).FirstOrDefault;
      if lDefault = nil then raise new OxygeneBinderException(Resources.strNoDefaultProperty);
      fName := lDefault.MemberName;
    end;
    var lField := lType.GetField(Name, BindingFlags.Static or BindingFlags.Public or BindingFlags.IgnoreCase);
    if (lField <> nil) then begin
        
      var lExpr: Expression;
      lExpr := Expression.Field(nil, lField);
      if (lExpr.Type.IsValueType)  then
        lExpr := Expression.Convert(lExpr, typeOf(Object));
      exit new DynamicMetaObject(lExpr, lRestrict);
    end;

    lPosibilities := OxygeneInvokeMemberBinder.GetPropertyAccessors(lType, fName, true,  false);
    if (OxygeneBinderFlags.GetMember in fFlags) and (lPosibilities = nil) then begin
      var lPos := lType.GetMethods(BindingFlags.Public or BindingFlags.Static);
      if lPos <> nil then lPos := lPos.Where(a->fName = a.Name).ToArray;
      if length(lPos) = 0 then exit OxygeneInvokeMemberBinder.Failure(target, nil, errorSuggestion, String.Format(Resources.strNoPropertiesByThatName, fName, lType));
      lPosibilities := new List<MethodBase>();
      for each el in lPos do 
        lPosibilities.Add(el);
    end;

    if lPosibilities = nil then
      exit OxygeneInvokeMemberBinder.Failure(target, nil, errorSuggestion, String.Format(Resources.strNoPropertiesByThatName, fName, lType));
  end else begin
    var lType := target.LimitType;
    if String.IsNullOrEmpty(fName) then begin
      var lDefault := array of DefaultMemberAttribute(lType.GetCustomAttributes(typeOf(DefaultMemberAttribute), true)).FirstOrDefault;
      if lDefault = nil then exit OxygeneInvokeMemberBinder.Failure(target, nil, errorSuggestion, Resources.strNoDefaultProperty);
      fName := lDefault.MemberName;
    end;

    var lField := lType.GetField(Name, BindingFlags.Instance or BindingFlags.Public or BindingFlags.IgnoreCase);
    if (lField <> nil) then begin
        
      var lExpr: Expression;
      lExpr := Expression.Field(Expression.Convert(target.Expression, target.LimitType), lField);
      if (lExpr.Type.IsValueType)  then
        lExpr := Expression.Convert(lExpr, typeOf(Object));
      exit new DynamicMetaObject(lExpr, lRestrict);
    end;

    lPosibilities := OxygeneInvokeMemberBinder.GetPropertyAccessors(lType, fName, false, false);
    if (OxygeneBinderFlags.GetMember in fFlags) and (lPosibilities = nil)  then begin
      var lPos := lType.GetMethods(BindingFlags.Public or BindingFlags.Instance);
      if lPos <> nil then lPos := lPos.Where(a->a.Name = fName).ToArray;
      if length(lPos) = 0 then exit OxygeneInvokeMemberBinder.Failure(target, nil, errorSuggestion, String.Format(Resources.strNoPropertiesByThatName, fName, lType));
      lPosibilities := new List<MethodBase>();
      for each el in lPos do 
        lPosibilities.Add(el);
    end;
    if lPosibilities = nil then
      exit OxygeneInvokeMemberBinder.Failure(target, nil, errorSuggestion, String.Format(Resources.strNoPropertiesByThatName, fName, lType));
  end;
  // calls, or finds field or property; 
  // name = null means default property (for get/set member)
  // name = null means ctor for staticcall without get/set
  // both instance and static call needs a "self" as the first parameter. (Static needs a System.Type instance)
  var lExpr: Expression;

  var lMatch := OxygeneInvokeMemberBinder.FindMatch(fTypeArgs, lPosibilities, []);
  if lMatch = nil then begin
    exit OxygeneInvokeMemberBinder.Failure(target, nil, errorSuggestion, Resources.strNoOverloadWithTheseParameters);
  end;
  if lMatch.Item3 <> nil then 
    lExpr := lMatch.Item3
  else 
  try
    if lMatch.Item1 is ConstructorInfo then
      lExpr := Expression.New(ConstructorInfo(lMatch.Item1), lMatch.Item2)
    else if lStatic then
      lExpr := Expression.Call(MethodInfo(lMatch.Item1), lMatch.Item2)
    else 
      lExpr := Expression.Call(Expression.Convert(target.Expression, target.LimitType), MethodInfo(lMatch.Item1), lMatch.Item2);

    if (lExpr.Type = nil) or (lExpr.Type = typeOf(Void)) then
      lExpr := Expression.Block(lExpr, Expression.Constant(nil, typeOf(Object)));
  except
    on e: Exception do begin
      lExpr := Expression.Block(Expression.Throw(Expression.Constant(e)), Expression.Constant(nil, typeOf(Object)));
    end;
  end;
  if (lExpr.Type.IsValueType)  then
    lExpr := Expression.Convert(lExpr, typeOf(Object));
  exit new DynamicMetaObject(lExpr, lRestrict);
end;

constructor OxygeneSetMemberBinder(aFlags: OxygeneBinderFlags; aName: String; aCount: Integer; aTypeArgs: Array of &Type);
begin
  inherited constructor(aName, true);
  fFlags := aFlags;
  fTypeArgs := aTypeArgs;
end;

method OxygeneSetMemberBinder.FallbackSetMember(target, value, errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  var lStatic := OxygeneBinderFlags.StaticCall in fFlags;
  fName := Name;
  var lPosibilities: List<MethodBase>;
  var lRestrict := OxygeneBinder.Restrict(nil, target);
  lRestrict := OxygeneBinder.Restrict(lRestrict, value);
  if lStatic then begin
    var lType := target.Value as &Type;
    if String.IsNullOrEmpty(fName) then begin
      var lDefault := array of DefaultMemberAttribute(lType.GetCustomAttributes(typeOf(DefaultMemberAttribute), true)).FirstOrDefault;
      if lDefault = nil then raise new OxygeneBinderException(Resources.strNoDefaultProperty);
      fName := lDefault.MemberName;
    end;
    var lField := lType.GetField(Name, BindingFlags.Static or BindingFlags.Public or BindingFlags.IgnoreCase);
    if (lField <> nil) then begin
      var lExpr: Expression;
      lExpr := Expression.Assign(Expression.Field(nil, lField),  OxygeneBinder.IntConvert(value.Expression, value.LimitType, lField.FieldType));
      if (lExpr.Type.IsValueType)  then
        lExpr := Expression.Convert(lExpr, typeOf(Object));
      exit new DynamicMetaObject(lExpr, lRestrict);
    end;

    lPosibilities := OxygeneInvokeMemberBinder.GetPropertyAccessors(lType, fName, true,  true);

    if lPosibilities = nil then
      exit OxygeneInvokeMemberBinder.Failure(target, [value], errorSuggestion, String.Format(Resources.strNoPropertiesByThatName, fName, lType));
  end else begin
    var lType := target.LimitType;
    if String.IsNullOrEmpty(fName) then begin
      var lDefault := array of DefaultMemberAttribute(lType.GetCustomAttributes(typeOf(DefaultMemberAttribute), true)).FirstOrDefault;
      if lDefault = nil then exit OxygeneInvokeMemberBinder.Failure(target, [value], errorSuggestion, Resources.strNoDefaultProperty);
      fName := lDefault.MemberName;
    end;

    var lField := lType.GetField(Name, BindingFlags.Instance or BindingFlags.Public or BindingFlags.IgnoreCase);
    if assigned(lField) then begin
      var lExpr: Expression;
          lExpr := Expression.Assign(Expression.Field(Expression.Convert(target.Expression, target.LimitType), lField),  OxygeneBinder.IntConvert(value.Expression, value.LimitType, lField.FieldType));
      if (lExpr.Type.IsValueType)  then
        lExpr := Expression.Convert(lExpr, typeOf(Object));
      exit new DynamicMetaObject(lExpr, lRestrict);
    end;
    lPosibilities := OxygeneInvokeMemberBinder.GetPropertyAccessors(lType, fName, false, true);
    if lPosibilities = nil then
      exit OxygeneInvokeMemberBinder.Failure(target, [value], errorSuggestion, String.Format(Resources.strNoPropertiesByThatName, fName, lType));
  end;
  // calls, or finds field or property; 
  // name = null means default property (for get/set member)
  // name = null means ctor for staticcall without get/set
  // both instance and static call needs a "self" as the first parameter. (Static needs a System.Type instance)
  var lExpr: Expression;

  var lMatch := OxygeneInvokeMemberBinder.FindMatch(fTypeArgs, lPosibilities, [value]);
  if lMatch = nil then begin
    exit OxygeneInvokeMemberBinder.Failure(target, [value], errorSuggestion, Resources.strNoOverloadWithTheseParameters);
  end;
  if lMatch.Item3 <> nil then 
    lExpr := lMatch.Item3
  else 
  try
    if lMatch.Item1 is ConstructorInfo then
      lExpr := Expression.New(ConstructorInfo(lMatch.Item1), lMatch.Item2)
    else if lStatic then
      lExpr := Expression.Call(MethodInfo(lMatch.Item1), lMatch.Item2)
    else 
      lExpr := Expression.Call(Expression.Convert(target.Expression, target.LimitType), MethodInfo(lMatch.Item1), lMatch.Item2);

    if (lExpr.Type = nil) or (lExpr.Type = typeOf(Void)) then
      lExpr := Expression.Block(lExpr, Expression.Constant(nil, typeOf(Object)));
  except
    on e: Exception do begin
      lExpr := Expression.Block(Expression.Throw(Expression.Constant(e)), Expression.Constant(nil, typeOf(Object)));
    end;
  end;
  if (lExpr.Type.IsValueType)  then
    lExpr := Expression.Convert(lExpr, typeOf(Object));
  exit new DynamicMetaObject(lExpr, lRestrict);

end;

end.
