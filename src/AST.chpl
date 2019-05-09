class ASTContext {
  var name : string;
  var roots : [0..-1] unmanaged ASTNode;
  
  proc init(name : string = "<anonymous>") {
    this.name = name;
  }

  proc readWriteThis(f) {
    f <~> "ASTContext{\nname=" + name + "\n" <~> roots <~> "\n}";
  }
}

class ASTNode {
  var context : unmanaged ASTContext;
  
  proc init(context : unmanaged ASTContext = nil) {
    this.context = context;
  }
  
  proc pushContext() {
    assert(this.hasContext());
    this.context.roots.push_back(this : unmanaged);
  }

  proc hasContext() return context != nil;
}

// Example: "x = 1 + 2"
class Decl : ASTNode {
  var lhs : unmanaged Name;
  var rhs : unmanaged ASTNode;
  var op : string;

  proc init(lhs :unmanaged Name, rhs : unmanaged ASTNode, op : string = "=") {
    assert(lhs.hasContext(), "Decl statement missing context for ", lhs);
    this.context = lhs.context;
    this.lhs = lhs;
    this.rhs = rhs;
    this.op = op;
    this.complete();
    this.pushContext();
  }

  proc init(lhs : string, rhs : unmanaged ASTNode, op : string = "=") {
    init(new Name(lhs));
  }

  proc readWriteThis(f) { f <~> lhs <~> " " + op + " " <~> rhs <~> ";"; }
}

// Example: "!x"
class UnaryOp : ASTNode {
  var op : string;
  var node : unmanaged ASTNode;
  
  proc readWriteThis(f) { f <~> op <~> node; }
}

// Example: "x + y"
class BinaryOp : ASTNode {
  var op : string;
  var lhs : unmanaged ASTNode;
  var rhs : unmanaged ASTNode;

  proc init(op : string, lhs : unmanaged ASTNode, rhs : unmanaged ASTNode) {
    super.init(lhs.context);
    this.op = op;
    this.lhs = lhs;
    this.rhs = rhs;
  }

  proc init(op : string, lhs, rhs : unmanaged ASTNode) where isASTNodeConstantType(lhs.type) {
    init(op, new unmanaged Constant(lhs), rhs);
  }
  
  proc init(op : string, lhs : unmanaged ASTNode, rhs) where isASTNodeConstantType(rhs.type) {
    init(op, lhs, new unmanaged Constant(rhs));
  }
  
  proc init(op : string, lhs, rhs) where isASTNodeConstantType(lhs.type) && isASTNodeConstantType(rhs.type) {
    init(op, new unmanaged Constant(lhs), new unmanaged Constant(rhs));
  }

  proc readWriteThis(f) { f <~> lhs <~> " " + op + " " <~> rhs; }
}

// Example: "x"
class Name : ASTNode {
  var name : string;
  proc init(name : string, context : unmanaged ASTContext) {
    this.name = name;
    this.context = context;
  }
  proc readWriteThis(f) { f <~> name; }
}

// Example: "1"
class Constant : ASTNode {
  type t;
  const _value : t;
  
  proc init(c : integral) {
    this.t = c.type;
    this._value = c;
  }
  
  proc init(c : real) {
    this.t = c.type;
    this._value = c;
  }
  
  proc deinit() { writeln("Deallocated: ", _value); }

  proc readWriteThis(f) { f <~> _value; }
}

proc isASTNodeConstantType(type t) param {
  return t == real || t == int;
}

proc +(x : unmanaged ASTNode, y : unmanaged ASTNode) {
  return new unmanaged BinaryOp("+", x, y);
}

proc +(x : unmanaged ASTNode, y) where isASTNodeConstantType(y.type) {
  return new unmanaged BinaryOp("+", x, y);
}

proc +=(x : unmanaged ASTNode, y : unmanaged ASTNode) {
  return new unmanaged BinaryOp("+=", x, y);
}

proc +=(x : unmanaged ASTNode, y) where isASTNodeConstantType(y.type) {
  return new unmanaged BinaryOp("+=", x, y);
}

proc -=(x : unmanaged ASTNode, y : unmanaged ASTNode) {
  return new unmanaged BinaryOp("-=", x, y);
}

proc -=(x : unmanaged ASTNode, y) where isASTNodeConstantType(y.type) {
  return new unmanaged BinaryOp("-=", x, y);
}

proc -(x : unmanaged ASTNode, y : unmanaged ASTNode) {
  return new unmanaged BinaryOp("-", x, y);
}

proc -(x : unmanaged ASTNode, y) where isASTNodeConstantType(y.type) {
  return new unmanaged BinaryOp("-", x, y);
}

proc =(ref x : unmanaged Name, y : unmanaged ASTNode) {
  new unmanaged Decl(x, y);
}

proc =(ref x : unmanaged Name, y) where isASTNodeConstantType(y.type) {
  new unmanaged Decl(x, new unmanaged Constant(y));
}

proc main() {
  var context = new unmanaged ASTContext("test_kernel");
  var x = new unmanaged Name("x", context);
  var y = new unmanaged Name("y", context);
  var z = new unmanaged Name("z", context);
  
  z = x + y + 1 + 2;
  writeln(context);
}
