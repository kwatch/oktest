// -*- coding: utf-8 -*-

///
/// $Release: $
/// $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
/// $License: MIT License $
///

/**
 * @fileoverview New-style testing library
 * @author $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
 * @license $License: MIT License $
 */


"use strict";

var oktest = {};

if (typeof(exports) === "object") {  // for node.js
  oktest = exports;
}

oktest.VERSION = '0.0.0';
oktest.encoding = 'utf-8';


/**
 * Utilities
 * @private
 */
oktest.util = {

  classdef: function classdef(constructor, method_def, static_def) {
    if (static_def) static_def(constructor);
    if (method_def) method_def(constructor.prototype);
    return constructor;
  },
  
  quote: function quote(str) {
    return "'" + str.replace(/\\/, '\\\\').replace(/\n/, '\\\\n\\').replace(/'/, "\\\\'") + "'";  //'
  },
  
  inspect: function inspect(value) {
    var t = typeof(value);
    if (t == "string")    return oktest.util.quote(value);
    if (t == "number")    return value.toString();
    if (t == "boolean")   return value ? "true" : "false";
    if (t == "undefined") return "undefined";
    if (t == "function")  return value.name ? "<function " + value.name + "()>" : "<function()>";
    if (t == "object") {
      if (value === null) return "null";
      var buf = [];
      if (value.constructor === Array) {  /// or Array.prototype
        for (var i = 0, n = value.length; i < n; i++) {
          buf.push(oktest.util.inspect(value[i]));
        }
        return "[" + buf.join(", ") + "]";
      }
      else {
        for (var p in value) {
          buf.push(p + ':' + oktest.util.inspect(value[p]));
        }
        return "{" + buf.join(", ") + "}";
      }
    }
    throw "unreachable: typeof(value)="+typeof(value)+", value="+value;
  },
  
  strip: function strip(str) {
    return str.replace(/^\s+/, '').replace(/\s+$/, '');
  },
  
  flatten: function flatten(arr) {
    var arr2 = [];
    for (var i = 0, n = arr.length; i < n; i++) {
      var item = arr[i];
      if (item instanceof Array) {
        arr2 = arr2.concat(oktest.util.flatten(item));
      }
      else {
        arr2.push(item);
      }
    }
    return arr2;
  },
  
  readFile: function readFile(filename) { },
  
  writeFile: function writeFile(filename) { },
  
  readLineInFile: function readLineInFile(filename, linenum) {
    var content = oktest.util.readFile(filename);
    //return content.split(/^/m)[linenum-1];   // fails sometimes in nodejs (maybe V8 bug)
    return content.split(/\r?\n/)[linenum-1];
  },
  
  _getLocationFromStack: function _getLocationFromStack(stack) {
    var line = stack.split(/^/m)[2];
    if (! line) return [null, null];
    var m = line.match(/\((.*):(\d+):(\d+)\)/) || line.match(/@(.*):(\d+)$/m);
    if (! m) return [null, null];
    return [m[1], m[2]-0]; // filepath, linenum
  },
  
  unifiedDiff: function unifiedDiff(text1, texdt2) {
  }
  
};


///
/// compatibility layer
///
oktest._engine = { nodejs: false, spidermoneky: false, rhino: false };
if (typeof(require) == 'function' && typeof(require.resolve) == 'function') { // node.js
  oktest._engine.nodejs = true;
  (function() {
    var system = require('system');
    oktest._args = oktest.util.flatten(system.args);
    oktest.print = system.print;  //require('sys').puts;
    var util = require("util");
    oktest.util.inspect = util.inspect;
    var fs = require("fs");
    oktest.util.readFile = function readFile(filename) {
      return fs.readFileSync(filename, oktest.encoding);
    };
    oktest.util.writeFile = function writeFile(filename, content) {
      return fs.writeFileSync(filename, content, oktest.encoding);
    };
    //oktest.util.system = function system(command) {
    //  var sout, serr, ex;
    //  var called = false;
    //  var callback = function (error, stdout, stderr) {
    //    sout = stdout;
    //    serr = stderr;
    //    ex   = error;
    //    called = true;
    //  };
    //  var child = require('child_process').exec(command, callback);
    //  //var x = 0;
    //  //while (! called) {
    //  //  x++;
    //  //}
    //  return [ex, sout, serr];
    //};
    //oktest.util.diff_u = function diff_u(content1, content2) {
    //  var fname1 = '__expected__', fname2 = '__actual__';
    //  oktest.util.writeFile(fname1, content1);
    //  oktest.util.writeFile(fname2, content2);
    //  var result = oktest.util.system("diff -u " + fname1 + " " + fname2);
    //  console.log('*** debug: result='); console.log(result);
    //  return result[1];
    //};
    oktest.util.unifiedDiff = function unifiedDiff(text1, text2) {
      //var diff_match_patch = require('./diff_match_patch.js');
      var diff_match_patch = require('diff_match_patch');
      var dmp = new diff_match_patch.diff_match_patch();
      var arr = dmp.diff_linesToChars(text1, text2);
      var chars1 = arr[0], chars2 = arr[1], char2line = arr[2];
      var diffs = dmp.diff_main(chars1, chars2, false);
      dmp.diff_charsToLines(diffs, char2line);
      //dmp.diff_cleanupSemantic(diffs);
      var sb = '';
      for (var i = -1, n = diffs.length; ++i < n; ) {
        var pair = diffs[i];
        var cmp  = pair[0];
        var text = pair[1];
        var sign = cmp > 0 ? '+' : cmp < 0 ? '-' : ' ';
        var s = text.replace(/^/mg, sign);
        if (text.match(/\n$/)) s = s.substring(0, s.length - 1);
        sb += s;
      }
      return sb;
    };
    
  })();
}
else if (typeof(java) == 'object' && typeof(Packages) == 'function') { // Rhino
  oktest._engine.rhino = true;
  oktest._args = arguments;
  oktest.print = print;
  oktest.util.readFile = function readFile(filename) {
    var reader = new java.io.BufferedReader(new java.io.FileReader(filename));
    //var buf = Array(512);
    //reader.read(buf, 0, 512); // Cannot convert org.mozilla.javascript.NativeArray@3c6a22 to char[]
    var line, lines = [];
    try {
      while ((line = reader.readLine()) != null) lines.push(line);
    } finally { reader.close(); }
    lines.push("");
    return lines.join("\n");
  };
  oktest.util.readLineInFile = function readLineInFile(filename, linenum) {
    var line;
    var reader = new java.io.BufferedReader(new java.io.FileReader(filename));
    try {
      for (var i = 1; (line = reader.readLine()) != null; i++) {
        if (i == linenum) break;
      }
    } finally { reader.close(); }
    return line;
  };
}
else if (typeof(print) == 'function') {  // SpiderMonkey
  oktest._engine.spidermoneky = true;
  oktest._args = arguments;
  oktest.print = print;
  oktest.util.readFile = function readFile(filename) {
    var f = File(filename);
    f.open('text,read');
    var max = 4096, buf = [], i = 0, s;
    try {
      while ((s = f.read(max)) != undefined) {  /// readfile() will exit if EOF. Why?
        buf[i++] = s;
        if (s.length < max) break;
      }
    } finally { f.close(); }
    return buf.join('');
  };
}
else {
  throw "*** Unknown JavaScript engine: oktest supports node.js, rhino, or spidermonkey.";
}


/**
 * Assertion error class which will be thrown if assertion by ok() is failed.
 *
 * @protected
 * @constructor
 * @param {string} message A string message to be displayed.
 */
oktest.AssertionError = function AssertionError(message) {
  Error.call(this, message);
  this.message = message;
};
//oktest.AssertionError.prototype = new Error();   // not work in node.js 0.4.7
oktest.AssertionError.prototype = {};
oktest.AssertionError.prototype.name = 'AssertionError';


oktest.AssertionObject = oktest.util.classdef(
  
  /**
   * Assertion object class which has a lot of assertion methods such as .eq() or .is().
   * Don't generate this object directly. Use ok() or NG() instead.
   *
   * @protected
   * @constructor
   * @param {any} left Any value passed to ok().
   * @param {boolean} bool True if returned by ok(). False if returned by NG.
   * @param {string} func_name Function name which generate this object (ex. 'ok' or 'NG').
   * @param {Array.<string>} stack Stack trace data of ok() or NG().
   */
  function AssertionObject(left, bool, func_name, stack) {
    this._left  = left;
    this._bool  = bool;
    this._func_name = func_name;
    this._stack = stack;
    this._done  = false;
    oktest.AssertionObject._instances.push(this);
  },
  
  /// instance methods
  function(def) {

    /**
     * Factory method to return AssertionError object with bulding message.
     *
     * @private
     * @param {any} right Any value to be passed to assertion method.
     * @param {string} message Message string containing the reason why assertion is failed.
     * @return {AssertionError} Assertion error object.
     */
    def._failed = function _failed(right, message) {
      this._right = right;
      this._message  = this._bool ? message : "NOT " + message;
      //return this;
      var ex = new oktest.AssertionError(this._message);
      ex._left  = this._left;
      ex._left  = this._right;
      ex._bool  = this._bool;
      ex._func_name = this._func_name;
      ex._stack = this._stack;
      ex._done  = this._done;
      return ex;
    };

    /**
     * Helper method to build error message.
     *
     * @private
     */
    def._msg = function _msg(left, op, right) {
      var inspect = oktest.util.inspect;
      if (op[0] === '.') {
        return inspect(left) + op + "(" + inspect(right) + ") : failed.";
      }
      else {
        return inspect(left) + " " + op + " " + inspect(right) + " : failed.";
      }
    };
    
    /**
     * Helper method of operator-like assertion methods.
     *
     * @private
     */
    def._cmp = function _cmp(op, right, compare) {
      this._done = true;
      var bool = compare(this._left, right);
      if (bool == this._bool) return;
      throw this._failed(right, this._msg(this._left, op, right));
    };
    
    /**
     * Assertion method equivarent to '==' operator.
     *
     * @public
     */
    def.eq = function eq(right) {
      //this._done = true;
      //var bool = this._left == right;
      //if (bool == this._bool) return;
      //var ex = this._failed(right, this._msg(this._left, "==", right));
      //if (typeof(right) == 'string') {
      //  ex._diff = oktest.util.unifiedDiff(right, this._left);
      //}
      //throw ex;
      var ex;
      try {
        return this._cmp("==", right, function(l, r) { return l == r; });
      }
      catch (ex) {
        if (ex instanceof oktest.AssertionError) {
          ex._diff = oktest.util.unifiedDiff(right, this._left);
        }
        throw ex;
      }
    };
    
    /**
     * Assertion method equivarent to '!=' operator.
     *
     * @public
     */
    def.ne = function ne(right) {
      return this._cmp("!=", right, function(l, r) { return l != r; });
    };
    
    /**
     * Assertion method equivarent to '==' operator.
     *
     * @public
     */
    def.is = function is(right) {
      return this._cmp("===", right, function(l, r) { return l === r; });
    };
    
    /**
     * Assertion method equivarent to '!==' operator.
     *
     * @public
     */
    def.isnt = function isnt(right) {
      return this._cmp("!==", right, function(l, r) { return l !== r; });
    };
    
    /**
     * Assertion method equivarent to '<' operator.
     *
     * @public
     */
    def.lt = function lt(right) {
      return this._cmp("<", right, function(l, r) { return l < r; });
    };
    
    /**
     * Assertion method equivarent to '>' operator.
     *
     * @public
     */
    def.gt = function gt(right) {
      return this._cmp(">", right, function(l, r) { return l > r; });
    };
    
    /**
     * Assertion method equivarent to '<=' operator.
     *
     * @public
     */
    def.le = function le(right) {
      return this._cmp("<=", right, function(l, r) { return l <= r; });
    };
    
    /**
     * Assertion method equivarent to '>=' operator.
     *
     * @public
     */
    def.ge = function ge(right) {
      return this._cmp(">=", right, function(l, r) { return l >= r; });
    };
    
    /**
     * Assertion method similar to '==' operator but takes delta.
     * For example, 'ok(v).inDelta(1, 0.01)' is same as 'ok(v).gt(0.99) && ok(v).lt(1.01)'.
     *
     * @public
     */
    def.inDelta = function inDelta(right, delta) {
      this._cmp(">", right - delta, function(l, r) { return l > r; });
      this._cmp("<", right + delta, function(l, r) { return l < r; });
    };
    
    /**
     * Assertion method equivarent to 'typeof' operator.
     * For example, 'ok(v).isTypeof("string")' is same as 'typeof(v) == "string"'.
     *
     * @public
     */
    def.isTypeof = function isTypeof(type) {
      this._done = true;
      var bool = typeof(this._left) == type;
      if (bool == this._bool) return;
      throw this._failed(type, "typeof(" + oktest.util.inspect(this._left) + ") == '" + type + "' : failed.");
    };
    
    /**
     * Assertion method equivarent to 'instanceof' operator.
     * For example, 'ok(v).isa(MyClass)' is same as 'v instanceof MyClass'.
     *
     * @public
     */
    def.isa = function isa(klass) {
      return this._cmp("instanceof", klass, function(l, r) { return l instanceof r; });
    };
    
    /**
     * Assertion method equivarent to 'str.match(pattern)'.
     *
     * @public
     */
    def.matches = function matches(pattern) {
      return this._cmp(".match", pattern, function(l, r) { return !! l.match(r); });
    };
    
    /**
     * Assertion method equivarent to [array] == [array], compareing each elements by '===' operator.
     *
     * @public
     */
    def.arrayEq = function arrayEq(right) {
      this._done = true;
      var errmsg = null;
      if (! (this._left instanceof Array)) {
        errmsg = "Array is expected but got "+this._left+".";
      }
      else if (! (right instanceof Array)) {
        errmsg = "Array is expected but got "+this._left+".";
      }
      else if (this._left.length !== right.length) {
        errmsg = this._msg(this._left, ".arrayEq", right);
      }
      else {
        for (var i = 0, n = this._left.length; i < n; i++) {
          if (this._left[i] !== right[i]) {
            errmsg = "[at index " + i + "] " + this._msg(this._left[i], "===", right[i]);
            break;
          }
        }
      }
      if (this._bool) {
        if (errmsg) throw this._failed(right, errmsg);
      }
      else {
        if (! errmsg) throw this._failed(right, this._msg(this._left, ".arrayEq", right));
      }
    };
    
    /**
     * Assertion method equivarent to 'in' operator.
     * For example, 'ok(key).inObject(obj)' is same as 'key in obj'.
     * Notice that 'ok(key).inObject(obj)' equals to 'ok(obj).hasKey(key)'.
     *
     * @public
     */
    def.inObject = function inObject(obj) {
      return this._cmp("in", obj, function(l, r) { return l in r; });
    };
    
    /**
     * Assertion method to check that value is in an array or not.
     * Notice that 'ok(item).inArray(arr)' equals to 'ok(arr).hasItem(item)'.
     *
     * @public
     */
    def.inArray = function inArray(arr) {
      function fn(item, arr) {
        for (var i = 0, n = arr.length; i < n; i++)
          if (arr[i] === item) return true;
        return false;
      }
      return this._cmp("exists in", arr, fn);
    };

    /**
     * Assertion method equivarent to 'in' operator.
     * For example, 'ok(obj).hasKey("x")' is same as '"x" in obj'.
     * Notice that 'ok(obj).hasKey(key)' equals to 'ok(key).inObject(obj)'.
     *
     * @public
     */
    def.hasKey = function hasKey(key) {
      this._done = true;
      var bool = key in this._left;
      if (bool == this._bool) return;
      throw this._failed(key, this._msg(key, "in", this._left));
    };
    
    /**
     * Assertion method to check whether item is in an array.
     * Notice that 'ok(arr).hasItem(item)' equals to 'ok(item).inArray(arr)'.
     *
     * @public
     */
    def.hasItem = function hasItem(item) {
      function fn(arr, item) {
        for (var i = 0, n = arr.length; i < n; i++)
          if (arr[i] === item) return true;
        return false;
      }
      return this._cmp("has item", item, fn);
    };
    
    /**
     * Assertion method to check whether exception is thrown or not.
     * For example, 'ok(func).throws_(TypeError, "number expected.")'
     * means that func() will throw TypeError with specified error message.
     *
     * Notice that both 'throws' is registered keyword of JavaScript.
     *
     * @public
     * @param {class} exception_cass Expected error class (or String).
     * @param {string} error_msg Expected error message (optional).
     */
    def.throws_ = function throws_(exception_class, error_msg) {
      this._done = true;
      if (! this._bool)
        throw new Error("throws() is not available with NG().");
      if (typeof(this._left) != 'function')
        throw new Error("throws() is available only with function object.");
      var errcls = exception_class;
      var inspect = oktest.util.inspect;
      if (typeof(errcls) !== "function")
        throw new TypeError(inspect(errcls) + ": Error class (or String class) expected.");
      var thrown = false;
      try {
        this._left();
      }
      catch (ex) {
        thrown = true;
        this._left.exception = ex;
        var flag_ok = errcls == String ? typeof(ex) === "string" : ex instanceof errcls;
        if (! flag_ok) {
          var got = (typeof(ex) == "object" && ex instanceof Error) ? ex.name + ' object' : inspect(ex);
          throw this._failed(errcls, errcls.name + " should be thrown : failed, got " + got + ".");
        }
        if (error_msg) {
          var actual = typeof(ex) === "string" ? ex : (ex instanceof Error ? ex.message : ex);
          if (error_msg !== actual) {
            throw this._failed(error_msg, inspect(error_msg) + " == " + inspect(actual) + " : failed.");
          }
        }
      }
      if (! thrown) {
        var expected = errcls == String && error_msg ? inspect(error_msg) : errcls.name;
        throw this._failed(expected, expected + " should be thrown : failed.");
      }
    };

    /**
     * Assertion method to check whether exception is thrown or not.
     * For example, 'ok(func).throws_(TypeError, "number expected.")'
     * means that func() will throw TypeError with specified error message.
     *
     * Notice that both 'throws' is registered keyword of JavaScript.
     *
     * @public
     */
    def.throwsNothing = function throwsNothing(exception) {
      this._done = true;
      if (! this._bool)
        throw "** ERROR: throwsNothing() is not available with NG().";
      if (typeof(this._left) != 'function')
        throw "** ERROR: throws() is available with function object.";
      try {
        this._left();
      }
      catch (ex) {
        var msg = "Nothing should be thrown : failed, got " + oktest.util.inspect(ex) + ".";
        throw this._failed(exception, msg);
      }
    };
    
  },
  
  /// class methods
  function(cls) {
    cls._instances = [];
  }
  
);


oktest.SkipException = oktest.util.classdef(
  
  /**
   * Exception class to skip some tests. Thrown by skipWhen().
   *
   * @protected
   * @param {string} reason Description why these tests are skipped?
   */
  function SkipException(reason) {
    this.reason = reason;
  },
  
  /// instance methods
  function(def) {
  }
  
);


/**
 * Factory function to generate positive AssertionObject.
 *
 * @public
 * @param {any} left Any value which is a subject of assertion.
 * @return an instance of AssertionObject
 */
oktest.ok = function ok(left) {
  return new oktest.AssertionObject(left, true, 'ok', new Error().stack);
};

/**
 * Factory function to generate negative AssertionObject.
 *
 * @public
 * @param {any} left Any value which is a subject of assertion.
 * @return an instance of AssertionObject
 */
oktest.NG = function NG(left) {
  return new oktest.AssertionObject(left, false, 'NG', new Error().stack);
};

/**
 * Precondition of assertions.
 * This is same as ok(), but meaning is different from ok().
 *
 * @public
 * @param {any} left Any value which is a subject of precondition.
 * @return an instance of AssertionObject
 */
oktest.preCond = function preCond(left) {
  /// same as ok() but it represents precodition rather than specification.
  return new oktest.AssertionObject(left, true, 'pre_cond', new Error().stack);
};

/**
 * Skip assertions (by throwing SkipException) when condition is true.
 *
 * @public
 * @param {bool} condition Throws SkipException if condition argument is true.
 * @param {string} reason Description why the following assertions are skipped?
 * @throw oktest.SkipException when condition is true
 */
oktest.skipWhen = function skipWhen(condition, reason) {
  if (condition) {
    throw new oktest.SkipException(reason);
  }
};

/**
 * @private
 * @return True if exception is thrown when assertion is failed.
 */
oktest.isFailed = function isFailed(ex) {
  return ex instanceof oktest.AssertionError;
};

/**
 * @private
 * @return True if exception is thrown by skipWhen().
 */
oktest.isSkipped = function isSkipped(ex) {
  return ex instanceof oktest.SkipException;
};


oktest.TargetObject = oktest.util.classdef(

  /**
   * Target object class generated by target() factory function.
   * Target object can contain specification objects or sub targets.
   *
   * @constructor
   * @private
   */
  function TargetObject(name, defun) {
    this.name = name;
    this.specs = [];
    this.results = {success: 0, failed: 0, error: 0, skipped: 0};
    this.status = null;   // '.':success, 'f':failed, 'E':error, 's':skipped
    oktest.TargetObject._all.push(this);
    var stack = oktest.TargetObject._stack;
    this.parent = stack[stack.length - 1];
    var depth = 0;
    for (var t = this; t.parent; t = t.parent) depth++;
    //for (var t = this, depth = 0; t.parent; t = t.parent, depth++);
    this.depth = depth;
    this._indent = (new Array(depth+1)).join("  ");
    stack.push(this);
    defun(this);
    stack.pop();
  },
  
  /// instance methods
  function(def) {

    /**
     * Accept method for Visitor pattern.
     *
     * @private
     */
    def.accept = function accept(visitor) {
      return visitor.visitTarget(this);
    };
    
    /**
     * Factory method to generate SpecObject.
     *
     * @public
     * @param {string} desc Specification text.
     * @param {function} body Body to execute assertions.
     * @return {SpecObject}
     */
    def.spec = function spec(desc, body) {
      var target_obj = this;
      var spec_obj = new oktest.SpecObject(target_obj, desc, body);
      this.specs.push(spec_obj);
      return spec_obj;
    };
    
    def.should = def.spec;  // alias
    
  },
  
  /// class methods
  function(cls) {
    cls._all = [];
    cls._stack = [];
  }
  
);


/**
 * Factory function to generate TargetObject.
 *
 * @public
 * @param {string|class} name Target name or class of specifications.
 * @param {function} defun Function object which contains specifications or sub targets.
 * @return {TargetObject}
 */
oktest.target = function target(name, defun) {
  return new oktest.TargetObject(name, defun);
};


oktest.SpecObject = oktest.util.classdef(
  
  /**
   * Specification object which contains assertions.
   *
   * @constructor
   * @private
   * @param {TargetObject} target_obj Parent of specification object.
   * @param {string} desc Specification text.
   * @param {function} body Function containing assertions.
   */
  function SpecObject(target_obj, desc, body) {
    this.target = target_obj;
    this.desc = desc;
    this.body = body;
    this.status = null;
  },
  
  /// instance methods
  function(def) {
    
    /**
     * Accept method for Visitor pattern.
     *
     * @private
     */
    def.accept = function accept(visitor) {
      return visitor.visitSpec(this);
    };
    
    def.after = null;
    
    /**
     * Display a message.
     *
     * @private
     */
    def.echo = function echo(message) {
      oktest.print(this.target._indent + "    " + message);
    };
    
  }
  
);


oktest.Runner = oktest.util.classdef(
  
  /**
   * Runs target objects and specification objects.
   *
   * @constructor
   * @private
   */
  function Runner() {
  },
  
  /// instance methods
  function(def) {

    /**
     * Callback method for Visitor pattern.
     *
     * @private
     */
    def.visit = function vist(acceptor) {
      acceptor.accept(this);
    };
    
    /**
     * Visitor method for Visitor pattern.
     *
     * @private
     */
    def.visitTarget = function visitTarget(target) {
      oktest.print(target._indent + "* " + target.name);
      var specs = target.specs;
      for (var spec, i = -1; spec = specs[++i]; ) spec.accept(this);
      var r = target.results;
      var total = r.success + r.failed + r.error + r.skipped;
      if (total > 0) this._reportTargetResult(total, target);
      //oktest.print('');
    };
    
    def._reportTargetResult = function _reportTargetResult(total, target) {
      for (var spec, i = -1; spec = target.specs[++i]; ) {
        if (spec._thrown) {
        }
      }
      var r = target.results;
      var str = 'total:' + total + ', success:' + r.success + ', failed:'
              + r.failed + ', error:' + r.error + ', skipped:' + r.skipped;
      oktest.print(target._indent + '  (' + str + ')');
    };
    
    /**
     * Callback method for Visitor pattern.
     *
     * @private
     */
    def.visitSpec = function visitSpec(spec) {
      //oktest.print(spec.target._indent + "  - " + spec.desc);
      var status = '';
      var msg = null;
      try {
        spec.body(spec);
        spec.target.results.success++;
        spec.status = '.';
        status = 'ok';
      }
      catch (ex) {
        spec._thrown = ex;
        if (oktest.isFailed(ex)) {        // oktest.AssertionError object
          spec.target.results.failed++;
          spec.status = 'f';
          status = 'Failed';
          msg = [ex.message].concat(this._getFailedMsg(ex));
        }
        else if (oktest.isSkipped(ex)) {  // oktest.SkipException
          spec.target.results.skipped++;
          spec.status = 's';
          status = 'Skipped';
          msg = ["reason: " + ex.reason];
        }
        else {
          spec.target.results.errored++;
          spec.status = 'E';
          status = 'ERROR';
          throw ex;
        }
      }
      finally {
        var indent = spec.target._indent + "  ";
        this._reportSpecResult(spec, indent, status, msg);
        this._checkSpecsDone(spec, indent, status);
        if (spec.after) spec.after();
      }
    };
    
    def._getFailedMsg = function _getFailedMsg(ass_ex) {
      var arr = oktest.util._getLocationFromStack(ass_ex._stack);
      var filepath = arr[0], linenum = arr[1];
      if (! filepath) return [];
      var line = oktest.util.readLineInFile(filepath, linenum);
      arr = ["(File " + filepath + ", line " + linenum + ")",
             "    " + oktest.util.strip(line)];
      if (ass_ex._diff) {
        console.log('*** debug: diff='+ass_ex._diff);
        arr = arr.concat(ass_ex._diff.split(/\r?\n/));
      }
      return arr;
    };
    
    def._reportSpecResult = function _reportSpecResult(spec, indent, status, msg) {
      oktest.print(indent + "- [" + status + "] "+ spec.desc);
      if (msg !== null) {
        for (var s, i = -1; s = msg[++i]; ) {
          oktest.print(indent + "  " + s);
        }
      }
    };
    
    def._checkSpecsDone = function _checkSpecsDone(spec, indent, status) {
      var ass_objs = oktest.AssertionObject._instances;
      for (var ass_obj, i = -1; ass_obj = ass_objs[++i]; ) {
        if (! ass_obj._done && status != 'ERROR') {
          var s = oktest.util._getLocationFromStack(ass_obj._stack).join(':');
          oktest.print(indent + "  # Warning: " + ass_obj._func_name
                       + "() is called but not tested yet. (" + s + ")");
        }
      }
      oktest.AssertionObject._instances = [];
    };
    
  }
  
);


/**
 * Runs all assertions in specifications.
 *
 * @public
 */
oktest.runAll = function runAll() {
  var runner = new oktest.Runner();
  var targets = oktest.TargetObject._all;
  for (var target, i = -1; target = targets[++i]; ) {
    target.accept(runner);
  }
};
