namespace RemObjects.Elements.Dynamic;

uses
  System.Threading,
  System.Threading.Tasks;

type
  DynamicTask = public static class
  public
    class method &Await(aValue: Object): Task<Object>;
    begin
      var lTask := aValue as Task;
      if not assigned(lTask) then
        raise new ArgumentException('Await requires a Task.', 'aValue');
      var lCompletion := new TaskCompletionSource<Object>;
      lTask.ContinueWith(t -> begin
        if t.IsCanceled then begin
          lCompletion.SetCanceled;
          exit;
        end;
        if t.IsFaulted then begin
          lCompletion.SetException(t.Exception.InnerExceptions);
          exit;
        end;
        try
          var lResult := t.GetType.GetProperty('Result');
          // Non-generic async methods may use Task<VoidTaskResult> internally.
          if not assigned(lResult) or (lResult.PropertyType.FullName = 'System.Threading.Tasks.VoidTaskResult') then
            lCompletion.SetResult(nil)
          else
            lCompletion.SetResult(lResult.GetValue(t, nil));
        except
          on e: Exception do
            lCompletion.SetException(e);
        end;
      end, CancellationToken.None, TaskContinuationOptions.ExecuteSynchronously, TaskScheduler.Default);
      exit lCompletion.Task;
    end;
  end;

end.
