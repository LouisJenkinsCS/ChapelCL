use AST;

// Used to generate a name for this array.
var numInstances : atomic int;

class Symbolic : BaseDist {
  var context : unmanaged ASTContext;
  proc init(context : unmanaged ASTContext) {
    this.context = context;
  }

  proc dsiClone() {
    return new unmanaged Symbolic(this.context);
  }

  proc dsiDisplayRepresentation() {
    writeln("SymbolicDist");
  }

  proc dsiEqualDMaps(other : this.type) {
    return this.context == other.context;
  }
  
  override
  proc dsiNewRectangularDom(param rank: int, type idxType, param stridable: bool, inds) {
    var dom = new unmanaged SymbolicDom(rank, idxType, stridable, inds, this:unmanaged);
    return dom;
  }

  proc add_dom(dom : unmanaged SymbolicDom) {

  }

}

class SymbolicDom : BaseRectangularDom {
  param rank: int;
  type idxType;
  param stridable: bool;
  var inds : range;
  var dist : unmanaged Symbolic;

  proc init(param rank : int, type idxType, param stridable : bool, inds : rank * range, dist) {
    super.init(rank, idxType, stridable);
    if rank != 1 then compilerWarning("SymbolicDom only supports 1D, truncating from ", rank, "D to 1D!");
    this.rank = 1;
    this.idxType = idxType;
    this.stridable = stridable;
    this.inds = inds[1];
    this.dist = dist;
  }

  proc dsiLow { return inds.low; }
  proc dsiHigh { return inds.high; }

  proc dsiMyDist() return dist;
  
  proc dsiGetIndices() return {0..0};

  proc dsiSetIndices(dom : SymbolicDom) {
    this.inds = dom.inds;
    this.stridable = dom.stridable;
  }
  
  proc dsiSetIndices(dom) {
    this.inds = dom.low..dom.high;
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
 
  proc dsiSerialWrite(f) {
    f <~> "(SYMBOLIC) {" <~> this.inds <~> "}";
  }

  proc dsiDisplayRepresentation() {
    dist.dsiDisplayRepresentation();
    writeln("(SYMBOLIC) {", this.inds, "}");
  }

  proc dsiBuildArray(type eltType) {
    var arr = new unmanaged SymbolicArr(eltType, this:unmanaged);
    return arr;
  }
}

class SymbolicArr : BaseArr {
  type eltType;
  var name : string;
  var dom : unmanaged SymbolicDom;
  var syms : c_ptr(unmanaged Name);

  proc init(type eltType, dom) {
    this.eltType = eltType;
    this.name = "__arr" + numInstances.fetchAdd(1) + "__";
    this.dom = dom;
    this.syms = c_malloc(unmanaged Name, dom.inds.size);
    for idx in 0..#dom.inds.size {
      this.syms[idx] = new unmanaged Name(this.name + "[" + idx + "]", dom.dist.context);
    }
  }

  proc dsiGetBaseDom() return dom;
  
  // Will handle cases like...
  // var symDom = {1..10} dmapped Symbolic(context);
  // var symArr : [symDom] int;
  // for i in symDom do symArr[i] += 1;
  // for a in symDom do a += 1;
  // symArr[1] = symArr[0] + symArr[1];
  proc dsiAccess(indexx) ref {
    return syms[indexx[1] - dom.inds.low];
  }

  proc dsiSerialWrite(f) {
    f <~> "(SYMBOLIC ARRAY) " + name + ": " <~> dom;
  }
  
  iter these() {
    yield syms[dom.inds.size];
    // TODO: First add an AST node to context that indicates we are in a 'for' loop from 'lo' to 'hi'
    // Then create a new 'Name' that will represent the loop variable at the symbolic 'index'
    // Then close the current loop.
  }
  
  iter these(param tag : iterKind) ref where tag == iterKind.leader {
    yield (0,);
  }
  
  iter these(param tag : iterKind, followThis) ref where tag == iterKind.follower {
    yield syms[dom.inds.size];
  }

  proc dsiReallocate(d: domain) {

  }
  
  proc dsiDisplayRepresentation() {
    writeln("(SYMBOLIC ARRAY) " + name);
    dom.dsiDsiplayRepresentation();
  }

  proc this(idx) {
    return dsiAccess(idx);
  }
}
