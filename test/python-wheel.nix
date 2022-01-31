assertMsg: pythonHello:
assert assertMsg
  (pythonHello ? wheel)
  "Expected pythonHello to build a wheel";
assert assertMsg
  (pythonHello ? package)
  "Expected pythonHello to build a package";
assert assertMsg
  (pythonHello.package ? wheel)
  "Expected pythonHello's packge to be a multi output derivation with a wheel";
{ }
