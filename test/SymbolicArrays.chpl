use SymbolicDist;
use CyclicDist;

var context = new unmanaged ASTContext();
var D = {1..10} dmapped Symbolic(context=context);
var A : [D] int;
for i in 1..10 do A[i] = i * 2;
//for a in A do a += 1;
writeln(context);
