use SymbolicDist;
use CyclicDist;

var context = new unmanaged ASTContext();
var D = {1..10} dmapped Symbolic(context=context);
var A : [D] int;
writeln("Created array!");
for i in 1..10 {
  writeln("Assigning A[", i, "]");
  A[i] = i * 2;
}
//for a in A do a += 1;
writeln(context);
