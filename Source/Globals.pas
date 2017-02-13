namespace RemObjects.Elements.System;

interface
uses
  System.Dynamic,
  System.Linq,
  System.Runtime.CompilerServices,
  System.Linq.Expressions;

 
{$G+}
operator Pow(a, b: Double): Double; public;
operator Pow(a, b: Int64): Int64; public;
operator Pow(a, b: Integer): Integer; public;

type
  AnsiChar = public record mapped to Byte end;

implementation


operator Pow(a, b: Double): Double; 
begin
  exit Math.Pow(a,b);
end;

operator Pow(a, b: Int64): Int64; 
begin
  result := 1;
  if b < 0 then exit 0;
  while b <> 0 do begin 
    if (b and 1) <> 0 then result := result * a;
    a := a * a;
    b := b shr 1;
  end;
end;

operator Pow(a, b: Integer): Integer; 
begin
  result := 1;
  if b < 0 then exit 0;
  while b <> 0 do begin 
    if (b and 1) <> 0 then result := result * a;
    a := a * a;
    b := b shr 1;
  end;
end;


end.
