uses PLP;

type
  Layer = sealed class
    prev: Layer;
    data := new List<BigInteger>;
    
    constructor(prev: Layer) :=
    self.prev := prev;
    
    function DataAt(x: integer): BigInteger;
    begin
      while data.Count<x do
      begin
        data +=
          (data.Count=0 ? 0 : data[data.Count-1]) +
          (prev=nil ? 1 : prev.DataAt(x))
      end;
      Result := data[x-1];
    end;
    
  end;
  
begin
  var curr_layer := new Layer(nil);
  var f := 1bi;
  for var l := 1 to 500 do
  begin
    $'Layer {l}:'.Print;
    
    var pts := ArrGen(l+1, x->(
      Fraction(x),
      Fraction(curr_layer.DataAt(x))
    ), 1);
    var pol := LagrangePolynomial(pts);
    
    f *= l;
    $'{new Fraction(1,f)} * ('.Print;
    
    pol.Select((k,i)->$'{k*f}*x^{i}').Skip(1).Reverse.Print(' + ');
    
    ' )'.Print;
    #10.Println;
    curr_layer := new Layer(curr_layer);
  end;
  
end.