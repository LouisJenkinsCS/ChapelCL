module OpenCL {

  extern {
    #include <OpenCL/opencl.h>
  }

  extern type cl_uint = uint;
  extern type cl_platform_id = c_void_ptr;
  extern type cl_device_type = int;
  extern type cl_device_info = int;
  extern type cl_device_id = c_void_ptr;
  extern record cl_mem {}

  extern proc clGetDeviceIDs(
      platform : cl_platform_id, 
      device_type : cl_device_type, 
      num_entries : cl_uint, 
      devices : c_ptr(cl_device_id), 
      num_devices : c_ptr(cl_uint)
  );
  
  extern proc clGetDeviceInfo(
      device : cl_device_id, 
      param_name : cl_device_info, 
      param_value_size : size_t, 
      param_value : c_void_ptr, 
      param_value_size_ret : c_ptr(size_t)
  );
  
  // Yields (name, version) pairs for all found devices of specified type.
  iter getDevices(deviceType = CL_DEVICE_TYPE_ALL) {
    var numDevices, i : cl_uint;
    clGetDeviceIDs(nil:cl_platform_id, deviceType, 0, nil, c_ptrTo(numDevices));
    var devices : [0..#numDevices:int] cl_device_id;
    clGetDeviceIDs(nil:cl_platform_id, deviceType, numDevices, c_ptrTo(devices), nil);
    
    // Print out all devices
    var deviceName, deviceVersion : [1..128] c_char;
    for i in 0..#numDevices:int {
        clGetDeviceInfo(devices[i], CL_DEVICE_NAME, 128, c_ptrTo(deviceName), nil);
        clGetDeviceInfo(devices[i], CL_DEVICE_VERSION, 128, c_ptrTo(deviceVersion), nil);
        yield (new string(c_ptrTo(deviceName):c_string), new string(c_ptrTo(deviceVersion):c_string)); 
    }
  }

  // Represents data structures that are responsible for representing instructions that will be responsible for
  // generating OpenCL code. These variables are represented _symbolically_ in that they do not hold an actual
  // value, but instead act as an 'alias' for a variable that will be declared in an actual GPU kernel.
  enum GPUVariableType {
    INT,
    FLOAT,
  };

  proc variableTypeToString(dtype : GPUVariableType) {
    return if dtype == GPUVariableType.INT then "int" else "float";
  }

  class GPUKernel {
    var scalarDom = {0..-1};
    var arrayDom = {0..-1};
    var scalars : [scalarDom] owned GPUScalar;
    var arrays : [arrayDom] owned GPUArray;

    proc createScalar(name : string, dtype : GPUVariableType) : GPUScalar {
      scalars.push_back(new owned GPUScalar(name, dtype));
      writeln(scalars[scalarDom.high].borrow(), ";");
      return scalars[scalarDom.high].borrow();
    }

    proc createArray(name : string, dtype : GPUVariableType, size) : GPUArray {
      arrays.push_back(new owned GPUArray(name, dtype, size));
      var arr = arrays[arrayDom.high].borrow();
      writeln(arr, " = malloc(sizeof(", variableTypeToString(arr.dtype), ") * ", arr.size.name, ");");
      return arr;
    }
  }

  class GPUVariable {
    
  }

  // Represents a normal scalar variable, I.E 'int x;' or 'float y;'
  class GPUScalar : GPUVariable {
    var name : string;
    var dtype : GPUVariableType;

    proc init(name : string, dtype : GPUVariableType) {
      this.name = name;
      this.dtype = dtype;
    }
    
    proc readWriteThis(f) {
      f <~> variableTypeToString(dtype) <~> new ioLiteral(" ") <~> name;
    }
  }

  proc +(x : GPUScalar, y : GPUScalar) {
    write(x.name, " + ", y.name);
    return x;
  }

  proc +(x : GPUScalar, y : integral)  {
    write(x.name, " + ", y);
    return x;
  }

  proc +=(ref x : GPUScalar, y : integral) {
    writeln(x.name, " += ", y);
  }

  proc +=(ref x : GPUScalar, y : GPUScalar) {
    writeln(x.name, " += ", y.name);
  }

  proc =(ref x : GPUScalar, y) {
    writeln(x.name, " = ", y, ";");
  }

  proc =(ref x : GPUScalar, ref y : GPUScalar) {
    writeln(x.name, " = ", y.name, ";");
  }
  
  // Represents an array of scalars. The array holds a single symbolic
  // variable that will be treated as the loop variable.
  class GPUArray : GPUVariable {
    var name : string;
    var dtype : GPUVariableType;
    var idx : owned GPUScalar;
    var elem : owned GPUScalar;
    var size : owned GPUScalar;
    
    proc init(name : string, dtype : GPUVariableType, size : integral) {
      this.name = name;
      this.dtype = dtype;
      this.idx = new owned GPUScalar(name="__idx__", dtype = GPUVariableType.INT);
      this.elem = new owned GPUScalar(name + "[" + this.idx.name + "]", dtype);
      this.size = new owned GPUScalar(name + "__size", dtype = GPUVariableType.INT);
      writeln(this.size, ";");
      // Emit value
      this.size = size;
    }

    proc init(name : string, dtype : GPUVariableType, size : GPUScalar) {
      this.name = name;
      this.dtype = dtype;
      this.idx = new GPUScalar(name="__idx__", dtype = GPUVariableType.INT);
      this.elem = new owned GPUScalar(name + "[" + this.idx.name + "]", dtype);
      this.size = new owned GPUScalar(size.name, size.dtype);
    }

    proc readWriteThis(f) {
      f <~> variableTypeToString(dtype) <~> new ioLiteral("* ") <~> name;
    }

    iter these() ref {
      writeln("for(", this.idx, " = ", 0, "; ", this.idx.name, " < ", this.size.name, "; ", this.idx.name, "++) {");
      yield elem;
      writeln("}");
    } 
  }

  proc main() {
    for (name, version) in getDevices() {
      writeln(name, " ~ ", version);
    }

    var kernel = new GPUKernel();
    var x = kernel.createScalar("x", GPUVariableType.INT);
    var arr = kernel.createArray("arr", GPUVariableType.INT, 10);
    for a in arr { 
      a += 1;
      x += a;
    }
  }
}
