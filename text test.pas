uses PLP;

begin
  Reset(input, 'input.txt');
  Rewrite(output, 'output.txt');
  
  var pts_count := ReadLexem.ToInteger;
  var pts := ArrGen(pts_count, i->(Fraction.Read, Fraction.Read) );
  pts.PrintLines;
  
  var pol := LagrangePolynomial(pts);
  Println;
  pol.Select((k,i)->$'{k}*x^{i}').Reverse.Print(' + ');
  
  output.Close;
  Exec('output.txt');
end.