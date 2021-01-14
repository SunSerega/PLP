uses PLP;

begin
  var pts_count := ReadInteger('Введите кол-во точек:');
  'Вводите по два числа на точку, в одном из двух форматов, "123.456" или "123/456":'.Println;
  var pts := ArrGen(pts_count, i->(Fraction.Read($'Точка {i}:'), Fraction.Read));
  var pol := LagrangePolynomial(pts);
  pol.Select((k,i)->$'{k}*x^{i}').Reverse.Print(' + ');
end.