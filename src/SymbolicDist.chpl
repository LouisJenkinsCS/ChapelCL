use AST;

class Symbolic {
  var context : ASTContext;
  proc init(context : ASTContext) {
    this.context = context;
  }

  proc dsiClone() {
    return new unmanaged SymbolicDist(this.context);
  }

  proc dsiDisplayRepresentation() {
    writeln("SymbolicDist");
  }

  proc dsiEqualDMaps(other : this.type) {
    return this.context == other.context;
  }

  proc dsiNewRectangularDom(param rank: int, type idxType, param stridable: bool, inds) {
    var dom = new SymbolicDom(rank, idxType, stridable, inds);
    dom.dist = this:unmanaged;
    return dom;
  }

}

class SymbolicDom : BaseRectangularDom {
  param rank: int;
  type idxType;
  param stridable: bool;
  var inds : range;
  var dist;

  proc init(param rank : int, type idxType, param stridable : bool, inds : range) {
    if rank != 1 then compilerWarning("SymbolicDom only supports 1D, truncating from ", rank, "D to 1D!");
    this.rank = 1;
    this.idxType = idxType;
    this.stridable = stridable;
    this.inds = inds;
  }

  proc dsiMyDist() return dist;
  
  proc dsiGetIndices() return {0..0};

  proc dsiSetIndices(dom : SymbolicDom) {
    this.inds = dom.inds;
    this.stridable = dom.stridable;
  }
  
  proc dsiSetIndices(dom) {
    this.inds = dom.low..dom.high;
    this.stridable = dom.stridable;
  }
  
  proc dsiSetIndices(ranges: rank * range(idxType)) {
    this.inds = ranges[1];
    this.stridable = ranges[1].stride != 1;
  }

  proc dsiAssignDomain(rhs: domain, lhsPrivate:bool) {
    this.dsiSetIndices(rhs);
  }

  iter these() {
    yield 0;
  }

  iter these(param tag) where tag == iterKind.leader {
    yield (0,);
  }

  iter these(param tag, followThis) where tag == iterKind.follower {
    yield 0;
  }

  iter these(param tag) where tag == iterKind.standalone {
    yield 0;
  }
 
  proc dsiSerialWrite(f: Writer) {
    f <~> "(SYMBOLIC) {" <~> this.inds <~> "}";
  }

  proc dsiDisplayRepresentation() {
    dist.dsiDisplayRepresentation();
    writeln("(SYMBOLIC) {", this.inds, "}");
  }

  proc dsiBuildArray(type eltType) {
    var arr = new SymbolicArr(eltType);
    arr.dom = this:unmanaged;
    return arr;
  }
}

class SymbolicArr : BaseArr {
  type eltType;
  var sym : SymbolicVariable;
  var dom;

  proc init(type eltType) {
    this.eltType = eltType;
    // Initialize name...
  }

  proc dsiGetBaseDom() return dom;
  
  // Will handle cases like...
  // var symDom = {1..10} dmapped Symbolic(context);
  // var symArr : [symDom] int;
  // for i in symDom do symArr[i] += 1;
  // for a in symDom do a += 1;
  // symArr[1] = symArr[0] + symArr[1];
  proc dsiAccess(indexx) ref {
    // Create a symbolic array access based on our name, 'arrName[indexx]' and return that
  }
}
