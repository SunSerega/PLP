unit PLP;

type
  Fraction = record
    public n, d: BigInteger;
    
    {$region Utils}
    
    /// Greatest Common Divisor
    private static function GCD(a, b: BigInteger): BigInteger;
    begin
      while true do
      begin
        
        a := a mod b;
        if a=0 then
        begin
          Result := b;
          exit;
        end;
        
        b := b mod a;
        if b=0 then
        begin
          Result := a;
          exit;
        end;
        
      end;
    end;
    
    public procedure Normalize;
    begin
      if d.IsZero then
      begin
        n := n.Sign;
        exit;
      end;
      if n.IsZero then
      begin
        d := 1;
        exit;
      end;
      
      var gcd := GCD(BigInteger.Abs(n), BigInteger.Abs(d));
      if gcd<>1 then
      begin
        self.n := n div gcd;
        self.d := d div gcd;
      end;
      
      if d<0 then
      begin
        n := -n;
        d := -d;
      end;
      
    end;
    
    {$endregion}
    
    {$region Type conversion}
    
    public constructor(n, d: BigInteger);
    begin
      self.n := n;
      self.d := d;
    end;
    
    public static function operator implicit(n: integer): Fraction := new Fraction(n, 1);
    public static function operator implicit(n: int64): Fraction := new Fraction(n, 1);
    public static function operator implicit(n: BigInteger): Fraction := new Fraction(n, 1);
    
    public function Round := (n + d div 2) div d;
    public function Round(margin: Fraction): Fraction;
    begin
      var gcd := GCD(BigInteger.Abs(self.d), BigInteger.Abs(margin.d));
      var d1 := self.d div gcd;
      var d2 := margin.d div gcd;
      Result.n := Fraction.Create(self.n*d2, margin.n*d1).Round;
      Result.d := margin.d;
      Result.Normalize;
    end;
    
    public static function operator implicit(r: real): Fraction;
    const E_size = 11;
    const M_size = 52;
    begin
      var i := PUInt64(pointer(@r))^;
      
      var M_mask := int64(1) shl M_size - 1;
      var E_mask := int64(1) shl E_size - 1;
      
      var M: int64   := i            and M_mask;
      var E: integer := i shr M_size and E_mask;
      var S: integer := i shr (M_size+E_size);
      
      S := S=0 ? 1 : -1;
      
      if E=0 then
      begin
        // 0 или real.Epsilon, считаем что всё равно 0
        Result := new Fraction(0, 1);
        exit;
      end else
      if E=E_mask then
      begin
        if M=0 then
          // +- бесконечность
          Result := new Fraction(S, 0) else
          // NaN
          Result := new Fraction(0, 0);
        exit;
      end;
      
      M += M_mask+1;
      E -= M_size + E_mask div 2;
      
      if E<0 then
        Result := new Fraction(S*M, BigInteger.Pow(2, -E) ) else
        Result := new Fraction(S*M*BigInteger.Pow(2, E), 1);
      
      Result.Normalize;
    end;
    
    public static function operator explicit(f: Fraction): real;
    const E_size = 11;
    const M_size = 52;
    begin
      
      if f.d.IsZero then
      begin
        Result := f.n.Sign / 0;
        exit;
      end else
      if f.n.IsZero then
      begin
        Result := 0;
        exit;
      end;
      
      var sign := 1;
      if f.n.Sign=-1 then
      begin
        sign := -sign;
        f.n := -f.n;
      end;
      if f.d.Sign=-1 then
      begin
        sign := -sign;
        f.d := -f.d;
      end;
      
      // Находим экспоненту
      var E: integer := 0;
      var E_max := int64(1) shl (E_size-1);
      if f.n >= f.d then
      begin
        var k := f.n div f.d;
        while k >= 2 do
        begin
          E += 1;
          if E=E_max then
          begin
            Result := real.PositiveInfinity * sign;
            exit;
          end;
          k := k div 2;
        end;
        f.d *= BigInteger.Pow(2, E);
      end else
      begin
        var E_min := 1 - E_max;
        var k := (f.d-1) div f.n + 1;
        var k2 := 1bi;
        while k2 < k do
        begin
          E -= 1;
          if E=E_min then
          begin
            Result := 0;
            exit;
          end;
          k2 *= 2;
        end;
        f.n *= BigInteger.Pow(2, -E);
      end;
      
      // Находим мантису
      f.n -= f.d;
      f.n *= int64(1) shl M_size;
      var biM := f.Round;
      {$ifdef DEBUG}
      if uint64(biM) >= uint64(1) shl M_size then raise new System.InvalidOperationException;
      {$endif DEBUG}
      var M := int64(biM);
      
      E += E_max-1;
      var i := (int64(sign<0) shl E_size + E) shl M_size + M;
      Result := PReal(pointer(@i))^;
    end;
    
    public function ToString: string; override;
    begin
      if d.IsZero then
        Result := (n.Sign/0).ToString else
      if n.IsZero then
        Result := '0' else
      if d.IsOne then
        Result := n.ToString else
        Result := $'{n}/{d}';
    end;
    
    public function Print: Fraction;
    begin
      ToString.Print;
      Result := self;
    end;
    public function Println: Fraction;
    begin
      ToString.Println;
      Result := self;
    end;
    
    public static function Parse(l: string): Fraction;
    begin
      var p := l.Split('.', '/');
      if p.Length>2 then raise new System.FormatException($'Ожидалось выражение типа "num/num" или "num.num"');
      if p.Length=1 then
      begin
        Result := BigInteger.Parse(l);
      end else
      if l.Contains('.') then
      begin
        Result.n := BigInteger.Parse(p[0]+p[1]);
        Result.d := BigInteger.Pow(10, p[1].Length);
        Result.Normalize;
      end else
      begin
        Result := new Fraction(
          BigInteger.Parse(p[0]),
          BigInteger.Parse(p[1])
        );
        Result.Normalize;
      end;
    end;
    public static function Read(prompt: string := nil): Fraction;
    begin
      if prompt<>nil then prompt.Print;
      Result := Parse(ReadLexem);
    end;
    public static function Readln(prompt: string := nil): Fraction;
    begin
      if prompt<>nil then prompt.Print;
      Result := Parse(ReadlnString);
    end;
    
    {$endregion Type conversion}
    
    {$region operator's}
    
    public static function operator+(f1, f2: Fraction): Fraction;
    begin
      var gcd := f1.d.IsZero or f2.d.IsZero ? 1 : GCD(BigInteger.Abs(f1.d), BigInteger.Abs(f2.d));
      var k1 := f2.d div gcd;
      var k2 := f1.d div gcd;
      Result := new Fraction(
        f1.n*k1 + f2.n*k2,
        f1.d*k1
      );
      Result.Normalize;
    end;
    
    public static function operator-(f1, f2: Fraction): Fraction;
    begin
      var gcd := f1.d.IsZero or f2.d.IsZero ? 1 : GCD(BigInteger.Abs(f1.d), BigInteger.Abs(f2.d));
      var k1 := f2.d div gcd;
      var k2 := f1.d div gcd;
      Result := new Fraction(
        f1.n*k1 - f2.n*k2,
        f1.d*k1
      );
      Result.Normalize;
    end;
    
    public static function operator*(f1, f2: Fraction): Fraction;
    begin
      Result := new Fraction(f1.n*f2.n, f1.d*f2.d);
      Result.Normalize;
    end;
    
    public static function operator/(f1, f2: Fraction): Fraction;
    begin
      Result := new Fraction(f1.n*f2.d, f1.d*f2.n);
      Result.Normalize;
    end;
    
    public static procedure operator+=(var f1: Fraction; f2: Fraction) := f1 := f1+f2;
    public static procedure operator-=(var f1: Fraction; f2: Fraction) := f1 := f1-f2;
    public static procedure operator*=(var f1: Fraction; f2: Fraction) := f1 := f1*f2;
    public static procedure operator/=(var f1: Fraction; f2: Fraction) := f1 := f1/f2;
    
    {$endregion operator's}
    
  end;
  
/// Takes in array of points
/// Returns polynomial coefficients
function LagrangePolynomial(params pts: array of (Fraction, Fraction)): array of Fraction;
begin
  Result := ArrFill&<Fraction>(pts.Length, 0);
  
  for var i1 := 0 to pts.Length-1 do
  begin
    var p1 := pts[i1];
    var res := ArrFill&<Fraction>(pts.Length, 0);
    res[res.Length-1] := p1[1]; // Y[j] умножается на весь многочлен одной строки
    
    var p := res.Length-1;
    for var i2 := 0 to pts.Length-1 do
      if i1 <> i2 then
      begin
        var p2 := pts[i2];
        var k := 1 / (p1[0] - p2[0]);
        
        for var i3 := p to res.Length-1 do
          res[i3-1] := (res[i3-1] - res[i3]*p2[0]) * k;
        res[res.Length-1] *= k;
        
        p -= 1;
      end;
    
    for var i2 := 0 to pts.Length-1 do
      Result[i2] += res[i2];
  end;
  
end;

end.