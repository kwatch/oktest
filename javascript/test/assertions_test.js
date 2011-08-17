//var vows   = require("vows");
var assert = require("assert");
var fs     = require("fs");
var util   = require("util");

if (! assert.match) {
  assert.match = function match(actual, rexp) {
    assert.ok(actual.match(rexp));
  };
}
if (! assert.instanceOf) {
  assert.instanceOf = function instanceOf(actual, classobj) {
    assert.ok(actual instanceof classobj);
  };
}

var oktest = require("oktest");
var ok = oktest.ok;
var NG = oktest.NG;

function _shouldBeFailed(func, errmsg) {
  var exception = null;
  try {
    func();
  }
  catch (ex) {
    exception = ex;
    if (! (ex instanceof assert.AssertionError))
      throw ex;
    if (errmsg)
      assert.equal(ex.message, errmsg);
  }
  if (! exception)
    assert.fail("Assertion should be failed, but not.");
  return exception;
}


//var suite = vows.describe("oktest.assertion").addBatch({
var tests = {

  "AssertionObject": {

    ///
    "eq()": {
      "pass": function() {
        ok (1+1).eq(2);
        ok (1+1, '==', 2);
        ok ("1").eq(1);
        ok (null).eq(undefined);
      },
      "fail": function() {
        var msg =
              "$actual == $expected : failed.\n" +
              "  $actual  : 2\n" +
              "  $expected: 3";
        _shouldBeFailed(function() { ok (1+1).eq(3); }, msg);
        _shouldBeFailed(function() { ok (1+1, '==', 3); }, msg);
      },
      "self": function() {
        var o = ok (1+1);
        assert.ok(o.eq(2) === o);
        assert.ok(ok (1+1, '==', 2) instanceof oktest.assertion.AssertionObject);
      }
    },
    ///
    "ne()": {
      "pass": function() {
        ok (1+1).ne(3);
        ok (1+1, '!=', 3);
      },
      "fail": function() {
        var msg =
              "$actual != $expected : failed.\n" +
              "  $actual  : 2\n" +
              "  $expected: 2";
        _shouldBeFailed(function() { ok (1+1).ne(2); }, msg);
        _shouldBeFailed(function() { ok (1+1, '!=', 2); }, msg);
      },
      "self": function() {
        var o = ok (1+1);
        assert.ok(o.ne(3) === o);
        assert.ok(ok (1+1, '!=', 3) instanceof oktest.assertion.AssertionObject);
      }
    },
    ///
    "is()": {
      "pass": function() {
        ok (1+1).is(2);
        ok (1+1, '===', 2);
        ok (null).is(null);
      },
      "fail": function() {
        var msg =
              "$actual === $expected : failed.\n" +
              "  $actual  : 2\n" +
              "  $expected: 3";
        _shouldBeFailed(function() { ok (1+1).is(3); }, msg);
        _shouldBeFailed(function() { ok (1+1, '===', 3); }, msg);
        //
        msg =
          "$actual === $expected : failed.\n" +
          "  $actual  : '1'\n" +
          "  $expected: 1";
        _shouldBeFailed(function() { ok ("1").is(1); }, msg);
        msg =
          "$actual === $expected : failed.\n" +
          "  $actual  : undefined\n" +
          "  $expected: null";
        _shouldBeFailed(function() { ok (undefined).is(null); }, msg);
      },
      "self": function() {
        var o = ok (1+1);
        assert.ok(o.is(2) === o);
        assert.ok(ok (1+1, '===', 2) instanceof oktest.assertion.AssertionObject);
      }
    },
    ///
    "isNot()": {
      "pass": function() {
        ok (1+1).isNot(3);
        ok (1+1, '!==', 3);
        ok (null).isNot(undefined);
        ok ("1").isNot(1);
      },
      "fail": function() {
        var msg =
              "$actual !== $expected : failed.\n" +
              "  $actual  : 2\n" +
              "  $expected: 2";
        _shouldBeFailed(function() { ok (1+1).isNot(2); }, msg);
        _shouldBeFailed(function() { ok (1+1, '!==', 2); }, msg);
        //
        msg =
          "$actual !== $expected : failed.\n" +
          "  $actual  : '1'\n" +
          "  $expected: '1'";
        _shouldBeFailed(function() { ok ("1").isNot("1"); }, msg);
        msg =
          "$actual !== $expected : failed.\n" +
          "  $actual  : null\n" +
          "  $expected: null";
        _shouldBeFailed(function() { ok (null).isNot(null); }, msg);
      },
      "self": function() {
        var o = ok (1+1);
        assert.ok(o.isNot(3) === o);
        assert.ok(ok (1+1, '!==', 3) instanceof oktest.assertion.AssertionObject);
      }
    },
    ///
    "gt()": {
      "pass": function() {
        ok (3).gt(2);
      },
      "fail": function() {
        var msg =
              "$actual > $expected : failed.\n" +
              "  $actual  : 2\n" +
              "  $expected: ";
        _shouldBeFailed(function() { ok (2).gt(2); }, msg + "2");
        _shouldBeFailed(function() { ok (2).gt(3); }, msg + "3");
      },
      "self": function() {
        var o = ok (3);
        assert.ok(o.gt(2) === o);
        assert.ok(ok (3, '>', 2) instanceof oktest.assertion.AssertionObject);
      }
    },
    ///
    "ge()": {
      "pass": function() {
        ok (3).ge(2);
        ok (2).ge(2);
      },
      "fail": function() {
        var msg =
              "$actual >= $expected : failed.\n" +
              "  $actual  : 2\n" +
              "  $expected: ";
        _shouldBeFailed(function() { ok (2).ge(3); }, msg + "3");
      },
      "self": function() {
        var o = ok (3);
        assert.ok(o.ge(3) === o);
        assert.ok(ok (3, '>=', 3) instanceof oktest.assertion.AssertionObject);
      }
    },
    ///
    "lt()": {
      "pass": function() {
        ok (2).lt(3);
      },
      "fail": function() {
        var msg =
              "$actual < $expected : failed.\n" +
              "  $actual  : 3\n" +
              "  $expected: ";
        _shouldBeFailed(function() { ok (3).lt(3); }, msg + "3");
        _shouldBeFailed(function() { ok (3).lt(2); }, msg + "2");
      },
      "self": function() {
        var o = ok (2);
        assert.ok(o.lt(3) === o);
        assert.ok(ok (2, '<', 3) instanceof oktest.assertion.AssertionObject);
      }
    },
    ///
    "le()": {
      "pass": function() {
        ok (2).le(3);
        ok (3).le(3);
      },
      "fail": function() {
        var msg =
              "$actual <= $expected : failed.\n" +
              "  $actual  : 3\n" +
              "  $expected: ";
        _shouldBeFailed(function() { ok (3).le(2); }, msg + "2");
      },
      "self": function() {
        var o = ok (3);
        assert.ok(o.le(3) === o);
        assert.ok(ok (3, '<=', 3) instanceof oktest.assertion.AssertionObject);
      }
    },
    ///
    "deepEqual()": {
      "pass": function() {
        ok ({a:1, b:[2,3]}).deepEqual({a:1, b:[2,3]});
      },
      "fail": function() {
        var obj1 = {
          team: "SOS",
          members: [
            {name: "Haruhi", gender: "F"},
            {name: "Mikuru", gender: "F"},
            {name: "Yuki",   gender: "F"},
            {name: "Kyon",   gender: "M"},
            {name: "Itsuki", gender: "M"}
          ]
        };
        var obj2 = {
          team: "SOS",
          members: [
            {name: "Haruhi", gender: "F"},
            {name: "Mikuru", gender: "F"},
            {name: "Yuki",   gender: "F"},
            {name: "John Smith",   gender: "M"},
            {name: "Itsuki", gender: "M"}
          ]
        };
        function fn() {
          ok (obj1).deepEqual(obj2);
        }
        var msg = "assert.deepEqual($actual, $expected) : failed.\n"
                + "+++ $actual\n"
                + "--- $expected\n"
                + "@@ -3 +3\n"
                + "    [ { name: 'Haruhi', gender: 'F' },\n"
                + "      { name: 'Mikuru', gender: 'F' },\n"
                + "      { name: 'Yuki', gender: 'F' },\n"
                + "+     { name: 'John Smith', gender: 'M' },\n"
                + "-     { name: 'Kyon', gender: 'M' },\n"
                + "      { name: 'Itsuki', gender: 'M' } ] }\n"
                + " \\ No newline at end of file\n"
                + " ";
        _shouldBeFailed(fn, msg);
      },
      "self": function() {
        var o = ok ({a:1});
        assert.ok(o.deepEqual({a:1}) === o);
      }
    },
    ///
    "notDeepEqual()": {
      "pass": function() {
        ok ({a:1, b:[2,4]}).notDeepEqual({a:1, b:[2,3]});
      },
      "fail": function() {
        function fn() {
          ok ({a:1, b:[2,3]}).notDeepEqual({a:1, b:[2,3]});
        }
        var msg = "assert.notDeepEqual($actual, $expected) : failed, both are same.\n"
                + "  $actual  : { a: 1, b: [ 2, 3 ] }\n"
                + "  $expected: { a: 1, b: [ 2, 3 ] }";
        _shouldBeFailed(fn, msg);
      },
      "self": function() {
        var o = ok ({a:1});
        assert.ok(o.notDeepEqual({a:2}) === o);
      }
    },
    ///
    "arrayEqual()": {
      "pass": function() {
        ok ([1,2,3]).arrayEqual([1,2,3]);
      },
      "fail": function() {
        /// when actual is not an array
        _shouldBeFailed(function() { ok (arguments).arrayEqual([]); },
                        "$actual instanceof Array : failed.\n  $actual  : {}");
        /// when expected is not an array
        _shouldBeFailed(function() { ok ([]).arrayEqual(arguments); },
                        "$expected instanceof Array : failed.\n  $expected: {}");
        /// when lengths are different
        _shouldBeFailed(function() { ok ([1,2]).arrayEqual([1,2,3]); },
                        "$actual.length === $expected.length : failed.\n  $actual.length  : 2\n  $expected.length: 3");
        /// when item is different
        _shouldBeFailed(function() { ok ([1,2,4]).arrayEqual([1,2,3]); },
                        "$actual[2] === $expected[2] : failed.\n  $actual[2]  : 4\n  $expected[2]: 3");
      },
      "self": function() {
        var o = ok ([1]);
        assert.ok(o.arrayEqual([1]) === o);
      }
    },
    ///
    "inDelta()": {
      "pass": function() {
        ok (3.1415).inDelta(3.141, 0.001);
      },
      "fail": function() {
        var msg =
              "$actual < $expected : failed.\n" +
              "  $actual  : 3.1415\n" +
              "  $expected: 3.1412";
        _shouldBeFailed(function() { ok (3.1415).inDelta(3.141, 0.0002); }, msg);
      },
      "self": function() {
        var o = ok (3.1415);
        assert.ok(o.inDelta(3.141, 0.001) === o);
      }
    },
    ///
    "isa()": {
      "pass": function() {
        ok (new Error()).isa(Error);
        ok (new TypeError()).isa(Error);
      },
      "fail": function() {
        var msg =
              "$actual instanceof $expected : failed.\n" +
              "  $actual  : 'str'\n" +
              "  $expected: 3.1412";
        var ex = _shouldBeFailed(function() { ok ("str").isa(Error); });
        assert.match(ex.message,
                     /^\$actual instanceof \$expected : failed.\n  \$actual  : 'str'\n  \$expected: \{ \[Function: Error\]/);
      },
      "self": function() {
        var o = ok (new TypeError());
        assert.ok(o.isa(Error) === o);
      }
    },
    ///
    "inObject()": {
      "pass": function() {
        ok ("a").inObject({a:10, b:20});
      },
      "fail": function() {
        var msg =
              "$actual in $expected : failed.\n" +
              "  $actual  : 'a'\n" +
              "  $expected: { b: 20 }";
        _shouldBeFailed(function () { ok ("a").inObject({b:20}); }, msg);
      },
      "self": function() {
        var o = ok ("a");
        assert.ok(o.inObject({a:10}) === o);
      }
    },
    ///
    "inArray()": {
      "pass": function() {
        ok ("b").inArray(["a", "b", "c"]);
      },
      "fail": function() {
        var msg =
              "$actual exists in $expected : failed.\n" +
              "  $actual  : 'x'\n" +
              "  $expected: [ 'a', 'b', 'c' ]";
        _shouldBeFailed(function () { ok ("x").inArray(["a", "b", "c"]); }, msg);
      },
      "self": function() {
        var o = ok ("b");
        assert.ok(o.inArray(["a", "b", "c"]) === o);
      }
    },
    ///
    "hasAttr()": {
      "pass": function() {
        ok ({x:10}).hasAttr("x");
        ok ({x:10}).hasAttr("x", 10);
      },
      "fail": function() {
        // when attr name not exist
        var msg;
        msg = "'y' in $actual : failed.\n" +
              "  $actual  : { x: 10 }";
        _shouldBeFailed(function () { ok ({"x":10}).hasAttr("y"); }, msg);
        // when attr value is different
        msg = "$actual.x === $expected : failed.\n" +
              "  $actual.x: 10\n" +
              "  $expected: 11";
        _shouldBeFailed(function () { ok ({"x":10}).hasAttr("x", 11); }, msg);
      },
      "self": function() {
        var o = ok ({x:10});
        assert.ok(o.hasAttr('x') === o);
      }
    },
//    ///
//    "attr()": {
//      "pass": function() {
//        ok ({"x":10}).attr("x", 10);
//      },
//      "fail": function() {
//        var msg =
//              "$actual.x === $expected : failed.\n" +
//              "  $actual.x: 10\n" +
//              "  $expected: 11";
//        _shouldBeFailed(function () { ok ({"x":10}).attr("x", 11); }, msg);
//        msg =
//              "'y' in $actual : failed.\n" +
//              "  $actual  : { x: 10 }";
//        _shouldBeFailed(function () { ok ({"x":10}).attr("y", 11); }, msg);
//      },
//      "self": function() {
//        var o = ok ({x:10});
//        assert.ok(o.attr('x', 10) === o);
//      }
//    },
    ///
    "match()": {
      "pass": function() {
        ok ("Haruhi").match(/ru/);
        ok ("Mikuru").match(/ru/);
      },
      "fail": function() {
        var msg =
              "$actual.match(/ru/) : failed.\n" +
              "  $actual  : 'Yuki'";
        _shouldBeFailed(function () { ok ("Yuki").match(/ru/); }, msg);
      },
      "self": function() {
        var o = ok ("Haruhi");
        assert.ok(o.match(/ru/) === o);
      }
    },
    ///
    "length()": {
      "pass": function() {
        ok (['Haruhi', 'Mikuru', 'Yuki']).length(3); 
        ok ("Sasaki").length(6);
      },
      "fail": function() {
        var msg =
              "$actual.length === 5 : failed.\n" +
              "  $actual  : 'Sasaki'";
        _shouldBeFailed(function () { ok ("Sasaki").length(5); }, msg);
      },
      "self": function() {
        var o = ok ("Sasaki");
        assert.ok(o.length(6) === o);
      }
    },
    ///
    "throws_()": {
      "pass": function() {
        var fn = function() { var x = null; var y = x[1]; };
        var msg = "Cannot read property '1' of null";
        var rexp = /^Cannot read property '\d' of null$/;
        ok (fn).throws_(TypeError, msg);
        ok (fn).throws_(TypeError, rexp);
        ok (fn).throws_(TypeError);
        ok (fn).throws_(Error,     msg);
        ok (fn).throws_(Error,     rexp);
        ok (fn).throws_(Error);
        ok (fn).throws(TypeError, msg);
        ok (fn).throws(TypeError, rexp);
        ok (fn).throws(TypeError);
        ok (fn).throws(Error,     msg);
        ok (fn).throws(Error,     rexp);
        ok (fn).throws(Error);
      },
      "fail": function() {
        var fn = function() { var x = null; };
        var msg = "TypeError expected but not thrown.";
        _shouldBeFailed(function() { ok (fn).throws_(TypeError); }, msg);
        //
        fn = function() { throw new Error("dummy"); };
        var ex = _shouldBeFailed(function() { ok(fn).throws_(TypeError); });
        assert.match(ex.message, /^TypeError expected but got Error\./);
      },
      "self": function() {
        var fn = function() { var x = null; var y = x[1]; };
        var msg = "Cannot read property '1' of null";
        var o = ok (fn);
        assert.ok(o.throws_(TypeError, msg) === o);
      }
    },
    ///
    "notThrow()": {
      "pass": function() {
        var fn = function() { var x = null; };
        ok (fn).notThrow();
        ok (fn).notThrow(Error);
        var fn2 = function() { var x = null; var y = x[1]; }; // throws TypeError
        ok (fn).notThrow(ReferenceError);
      },
      "fail": function() {
        var fn = function() { var x = null; var y = x[1]; };
        var ex = _shouldBeFailed(function() { ok(fn).notThrow(); });
        assert.match(ex.message, /^Nothing should be thrown, but got TypeError./);
        ex = _shouldBeFailed(function() { ok(fn).notThrow(TypeError); });
        assert.match(ex.message, /^TypeError is unexpected, but thrown./);
      },
      "self": function() {
        var fn = function() { var x = null; };
        var o = ok (fn);
        assert.ok(o.notThrow() === o);
      }
    },
    ///
    "isFile()": {
      "pass": function() {
        var fname = "__tmp1.txt";
        var exception = null;
        try {
          fs.writeFileSync(fname, "content", "utf8");
          ok (fname).isFile();
          /// self
          var o = ok (fname); assert.ok(o.isFile() === o);
        }
        catch (ex) {
          exception = ex;
          throw ex;
        }
        finally {
          try { fs.unlink(fname); }
          catch (ignore) {   }
        }
        if (exception) throw exception;
      },
      "fail": function() {
        // when not exist
        var fname = "__tmp9.txt";
        var msg = "isFile($actual) : failed, not exist.\n"
                + "  $actual  : '__tmp9.txt'";
        _shouldBeFailed(function() { ok(fname).isFile(); }, msg);
        // when not a file
        try {
          fs.mkdirSync(fname, 0755);
          msg = "isFile($actual) : failed.\n"
              + "  $actual  : '__tmp9.txt'";
          _shouldBeFailed(function() { ok(fname).isFile(); }, msg);
        }
        finally {
          fs.rmdirSync(fname);
        }
      }
    },
    ///
    "isDirectory()": {
      "pass": function() {
        var fname = "__tmp1.dir";
        var exception = null;
        try {
          fs.mkdirSync(fname, 0755);
          ok (fname).isDirectory();
          /// self
          var o = ok (fname); assert.ok(o.isDirectory() === o);
        }
        catch (ex) {
          exception = ex;
          throw ex;
        }
        finally {
          try { fs.rmdir(fname); }
          catch (ignore) {   }
        }
        if (exception) throw exception;
      },
      "fail": function() {
        // when not exist
        var fname = "__tmp9.dir";
        var msg = "isDirectory($actual) : failed, not exist.\n"
                + "  $actual  : '__tmp9.dir'";
        _shouldBeFailed(function() { ok(fname).isDirectory(); }, msg);
        // when not a directory
        try {
          fs.writeFileSync(fname, "contents", "utf8");
          msg = "isDirectory($actual) : failed.\n"
              + "  $actual  : '__tmp9.dir'";
          _shouldBeFailed(function() { ok(fname).isDirectory(); }, msg);
        }
        finally {
          fs.unlinkSync(fname);
        }
      }
    },
    ///
    "notExist()": {
      "pass": function() {
        var fname = "__tmp1.notexist";
        ok (fname).notExist();
      },
      "fail": function() {
        var fname = "__tmp9.notexist";
        var msg, exception;
        //
        exception = null;
        try {
          fs.writeFileSync(fname, "content", "utf8");
          msg = "$actual expected not exist, but is a file.\n"
              + "  $actual  : '__tmp9.notexist'";
          _shouldBeFailed(function() { ok (fname).notExist(fname); }, msg);
        }
        catch (ex) {
          exception = ex;
          throw ex;
        }
        finally {
          try { fs.unlinkSync(fname); }
          catch (ignore) {   }
        }
        if (exception) throw exception;
        //
        exception = null;
        try {
          fs.mkdirSync(fname, 0755);
          msg = "$actual expected not exist, but is a directory.\n"
              + "  $actual  : '__tmp9.notexist'";
          _shouldBeFailed(function() { ok (fname).notExist(fname); }, msg);
        }
        catch (ex) {
          exception = ex;
          throw ex;
        }
        finally {
          try { fs.rmdirSync(fname); }
          catch (ignore) {   }
        }
        if (exception) throw exception;
      },
      "self": function() {
        var o = ok ("__notexist");
        assert.ok(o.notExist() === o);
      }
    },
    ///
    "isString()": {
      "pass": function() {
        ok ("SOS").isString();
      },
      "fail": function() {
        var msg = "typeof($actual) === 'string' : failed.\n"
                + "  $actual  : 123";
        _shouldBeFailed(function () { ok (123).isString(); }, msg);
      },
      "self": function() {
        var o = ok ("SOS");
        assert.ok(o.isString() === o);
      }
    },
    ///
    "isNumber()": {
      "pass": function() {
        ok (123).isNumber();
        ok (3.14).isNumber();
      },
      "fail": function() {
        var msg = "typeof($actual) === 'number' : failed.\n"
                + "  $actual  : 'SOS'";
        _shouldBeFailed(function () { ok ("SOS").isNumber(); }, msg);
      },
      "self": function() {
        var o = ok (123);
        assert.ok(o.isNumber() === o);
      }
    },
    ///
    "isBoolean()": {
      "pass": function() {
        ok (true).isBoolean();
        ok (false).isBoolean();
      },
      "fail": function() {
        var msg = "typeof($actual) === 'boolean' : failed.\n"
                + "  $actual  : null";
        _shouldBeFailed(function () { ok (null).isBoolean(); }, msg);
      },
      "self": function() {
        var o = ok (true);
        assert.ok(o.isBoolean() === o);
      }
    },
    ///
    "isUndefined()": {
      "pass": function() {
        ok (undefined).isUndefined();
      },
      "fail": function() {
        var msg = "typeof($actual) === 'undefined' : failed.\n"
                + "  $actual  : null";
        _shouldBeFailed(function () { ok (null).isUndefined(); }, msg);
      },
      "self": function() {
        var o = ok (undefined);
        assert.ok(o.isUndefined() === o);
      }
    },
    ///
    "isObject()": {
      "pass": function() {
        ok ({}).isObject();
        ok (null).isObject();
      },
      "fail": function() {
        var msg = "typeof($actual) === 'object' : failed.\n"
                + "  $actual  : undefined";
        _shouldBeFailed(function () { ok (undefined).isObject(); }, msg);
      },
      "self": function() {
        var o = ok ({});
        assert.ok(o.isObject() === o);
      }
    },
    ///
    "isFunction()": {
      "pass": function() {
        ok (function() { }).isFunction();
      },
      "fail": function() {
        var msg = "typeof($actual) === 'function' : failed.\n"
                + "  $actual  : null";
        _shouldBeFailed(function () { ok (null).isFunction(); }, msg);
      },
      "self": function() {
        var o = ok (function() {});
        assert.ok(o.isFunction() === o);
      }
    },
    ///
    "all()": {
      "pass": function() {
        var arr = ["Haruhi", "Mikuru", "Yuki"];
        ok (arr).all().isString();
        ok (arr).all().match(/u/);
      },
      "fail": function() {
        var arr = ["Haruhi", "Mikuru", "Yuki", null];
        var msg = "[index=3] typeof($actual) === 'string' : failed.\n  $actual  : null";
        _shouldBeFailed(function () { ok (arr).all().isString(); }, msg);
        var msg2 = "[index=2] $actual.match(/ru/) : failed.\n  $actual  : 'Yuki'";
        _shouldBeFailed(function () { ok (arr).all().match(/ru/); }, msg2);
      },
      "self": function() {
        var arr = ["Haruhi", "Mikuru", "Yuki"];
        var o = ok (arr).all();
        assert.ok(o.isString() === o);
      }
    }
  },

  "register()": {
    "pass": function() {
      function assertStartWith(bool, actual, expected) {
        var s = actual.substr(0, expected.length);
        if ((s === expected) === bool)
          return null;
        var errmsg = (bool ? "" : "NOT ")
          + "$actual starts with " + util.inspect(expected) + " : failed.\n"
          + "  $actual: " + util.inspect(actual);
        return errmsg;
      }
      //
      var exception = null;
      var fn = function() { ok ("Haruhi").startWith("Haru"); };
      assert['throws'](fn);
      oktest.assertion.register("startWith", assertStartWith);
      fn();
      ok ("Haruhi").startWith("Haruhi");
      assert['throws'](function() { ok ("Haruhi").startWith("Sasaki"); });
    }
  }

//});
};


//if (process.argv[1] === __filename) {
//  suite.run();
//}
//else {
//  suite.export(module);     // allow vows command to execute this script
//}

if (process.argv[1] === __filename) {
  (function(expected_count) {
    var count = 0;
    function run_func(fn) {
      count++;
      try {
        fn();
        util.print('.');
      }
      catch (ex) {
        util.print('E');
        throw ex;
      }
    }
    function run_obj(obj) {
      for (var k in obj) {
        var v = obj[k];
        typeof(v) === 'function' ? run_func(v) : run_obj(v);
      }
    }
    run_obj(tests);
    util.print(" (" + count + " tests finished)\n");
    assert.equal(count, expected_count);
  })(89);
}
