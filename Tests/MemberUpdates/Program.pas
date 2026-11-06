// Positive guards: dynamic events adapt delegates and preserve removal/multicast identity;
// ordinary member updates still use dynamic arithmetic and setters.
namespace MemberUpdates;
uses System, System.Runtime.CompilerServices, RemObjects.Elements.Dynamic;
type
  Source = public class
  public
    event Changed: EventHandler;
    class event GlobalChanged: EventHandler;
    class method FireGlobal;
    begin
      if assigned(GlobalChanged) then
        GlobalChanged(nil, EventArgs.Empty);
    end;
    property Number: Integer;
    property Text: String;
    method Fire;
    begin
      if assigned(Changed) then
        Changed(self, EventArgs.Empty);
    end;
  end;
  OtherSource = public class(Source)
  end;
  Sink = public class
  public
    property Count: Integer;
    method Handle(aSender: Object; aArgs: Object);
    begin
      Count := Count + 1;
    end;
  end;
  Program = public static class
  public
    class method Main;
    begin
      var lSource := new Source;
      var lSink := new Sink;
      var lHandler: &Delegate := new Action<Object, Object>(lSink.Handle);
      var lAdd := CallSite<Func<CallSite, Object, Func<Object>, Object>>.Create(OxygeneBinder.UpdateMember(OxygeneBinderFlags.None, 'Changed', false));
      var lRemove := CallSite<Func<CallSite, Object, Func<Object>, Object>>.Create(OxygeneBinder.UpdateMember(OxygeneBinderFlags.None, 'Changed', true));
      lAdd.Target(lAdd, lSource, () -> Object(lHandler));
      lSource.Fire;
      assert(lSink.Count = 1);
      lRemove.Target(lRemove, lSource, () -> Object(lHandler));
      lSource.Fire;
      assert(lSink.Count = 1);
      var lMulticast := &Delegate.Combine(lHandler, lHandler);
      lAdd.Target(lAdd, lSource, () -> Object(lMulticast));
      lSource.Fire;
      assert(lSink.Count = 3);
      lRemove.Target(lRemove, lSource, () -> Object(lMulticast));
      lSource.Fire;
      assert(lSink.Count = 3);
      var lOther := new OtherSource;
      lAdd.Target(lAdd, lOther, () -> Object(lHandler));
      lOther.Fire;
      assert(lSink.Count = 4);
      lRemove.Target(lRemove, lOther, () -> Object(lHandler));
      lOther.Fire;
      assert(lSink.Count = 4);
      var lNumber := CallSite<Func<CallSite, Object, Func<Object>, Object>>.Create(OxygeneBinder.UpdateMember(OxygeneBinderFlags.None, 'Number', false));
      lSource.Number := 10;
      lNumber.Target(lNumber, lSource, () -> Object(5));
      assert(lSource.Number = 15);
      var lText := CallSite<Func<CallSite, Object, Func<Object>, Object>>.Create(OxygeneBinder.UpdateMember(OxygeneBinderFlags.None, 'Text', false));
      lSource.Text := 'a';
      lText.Target(lText, lSource, () -> Object('b'));
      assert(lSource.Text = 'ab');
      var lStaticAdd := CallSite<Func<CallSite, Object, Func<Object>, Object>>.Create(OxygeneBinder.UpdateMember(OxygeneBinderFlags.StaticCall, 'GlobalChanged', false));
      var lStaticRemove := CallSite<Func<CallSite, Object, Func<Object>, Object>>.Create(OxygeneBinder.UpdateMember(OxygeneBinderFlags.StaticCall, 'GlobalChanged', true));
      lStaticAdd.Target(lStaticAdd, typeOf(Source), () -> Object(lHandler));
      Source.FireGlobal;
      assert(lSink.Count = 5);
      lStaticRemove.Target(lStaticRemove, typeOf(Source), () -> Object(lHandler));
      Source.FireGlobal;
      assert(lSink.Count = 5);
      lAdd.Target(lAdd, lSource, () -> nil);
      var lRejected := false;
      try
        lAdd.Target(lAdd, lSource, () -> Object(42));
      except
        on OxygeneBinderException do
          lRejected := true;
      end;
      assert(lRejected);
      writeLn('OK dynamic member updates');
    end;
  end;
end.
