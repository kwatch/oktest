

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


function _createDummyFile(filename, dirname) {
  fs.writeFileSync(filename, "foobar", "utf8");
  fs.mkdirSync(dirname, 0755);
  fs.mkdirSync(dirname + "/foo", 0755);
  fs.mkdirSync(dirname + "/foo/bar", 0755);
  fs.writeFileSync(dirname + "/foo/baz.txt", "baaaa", "utf8");
}

function shouldBeFile(path) {
  assert.ok(fs.statSync(path).isFile());
}

function shouldBeDirectory(path) {
  assert.ok(fs.statSync(path).isDirectory());
}

function shouldNotExist(path) {
  try {
    fs.statSync(path);
  }
  catch (ex) {
    if ('code' in ex && ex.code == 'ENOENT') {
      return true;
    }
    throw ex;
  }
  assert.fail("'"+path+"' expected not exist, but exists.");
  return "--unreachable--";
}


function shouldThrow(func, errclass, errmsg) {
  var exception = null;
  try {
    func();
  }
  catch (ex) {
    exception = ex;
    if (errmsg) assert.equal(ex.message, errmsg);
  }
  if (! exception) assert.fail(errclass+" expected but not thrown.");
  return exception;
}


//var suite = vows.describe("oktest.fixture.").addBatch({
var tests = {
  "invoke()": {
    topic: null,
    ////
    "invokes method without fixture.": function(topic) {
      var t1 = oktest.create();
      var _t1_called = false;
      t1.topic("outer", function() {
        t1.topic("inner", function() {
          t1.spec("injector calls method without fixture.", function() {
            _t1_called = true;
          });
        });
      });
      var out = new oktest.util.StringIO();
      assert.equal(_t1_called, false);
      t1.run({out:out, color:false});
      assert.equal(_t1_called, true);
      assert.match(out.value(), /passed:1, failed:0, error:0/);
    },
    ////
    "invokes method with fixturex.": function(topic) {
      var t2 = oktest.create();
      t2.topic("outer2", function() {
        t2.topic("inner2", function() {
          this.provideItem1 = function() { return 123; };
          t2.spec("injector calls method with fixtures.", function(item1, item2) {
            assert.equal(item1, 123);
            assert.equal(item2, "ABC");
          });
          this.provideItem2 = function() { return "ABC"; };
        });
      });
      var out = new oktest.util.StringIO();
      t2.run({out:out, color:false});
      assert.match(out.value(), /passed:1, failed:0, error:0/);
    },
    ////
    "invokes provider in parent topic.": function(topic) {
      var t03 = oktest.create();
      t03.topic("outer03", function() {
        t03.topic("inner03", function() {
          t03.spec("injector calls providers in parent topics.", function(item3, item4) {
            assert.equal(item3, 123);
            assert.equal(item4, "ABC");
          });
          this.provideItem3 = function() { return 123; };
        });
        this.provideItem4 = function() { return "ABC"; };
      });
      var out = new oktest.util.StringIO();
      t03.run({out:out, color:false});
      assert.match(out.value(), /passed:1, failed:0, error:0/);
    },
    ////
    "releaser is called.": function(topic) {
      var _released_item11a = null;
      var _released_item11b = null;
      var t11 = oktest.create();
      t11.topic("outer11", function() {
        t11.topic("inner11", function() {
          t11.spec("releaser is called.", function(item11a, item11b) {
            assert.equal(item11a, 123);
            assert.equal(item11b, "ABC");
          });
          this.provideItem11a = function() { return 123; };
          this.releaseItem11a = function(val) {
            _released_item11a = val;
          };
        });
        this.provideItem11b = function() { return "ABC"; };
        this.releaseItem11b = function(val) {
          _released_item11b = val;
        };
      });
      var out = new oktest.util.StringIO();
      t11.run({out:out, color:false});
      assert.match(out.value(), /passed:1, failed:0, error:0/);
      assert.equal(_released_item11a, 123);
      assert.equal(_released_item11b, "ABC");
    },
    ////
    "releasers are called.": function(topic) {
      var _released_item11a = null;
      var _released_item11b = null;
      var t11 = oktest.create();
      t11.topic("outer11", function() {
        t11.topic("inner11", function() {
          t11.spec("releaser is called.", function(item11a, item11b) {
            assert.equal(item11a, 123);
            assert.equal(item11b, "ABC");
          });
          this.provideItem11a = function() { return 123; };
          this.releaseItem11a = function(val) {
            _released_item11a = val;
          };
        });
        this.provideItem11b = function() { return "ABC"; };
        this.releaseItem11b = function(val) {
          _released_item11b = val;
        };
      });
      var out = new oktest.util.StringIO();
      t11.run({out:out, color:false});
      assert.match(out.value(), /passed:1, failed:0, error:0/);
      assert.equal(_released_item11a, 123);
      assert.equal(_released_item11b, "ABC");
    },
    ////
    "releasers are called only when defined on the save topic with corresponding provider.": function(topic) {
      var _released_item12x = null;
      var _released_item12y = null;
      var t12 = oktest.create();
      t12.topic("outer12", function() {
        t12.topic("inner12", function() {
          t12.spec("releaser may not be called.", function(item12x, item12y) {
            assert.equal(item12x, 123);
            assert.equal(item12y, "ABC");
          });
          this.provideItem12x = function() { return 123; };
          this.releaseItem12y = function(val) {
            _released_item12y = val;  // not called
          };
        });
        this.provideItem12y = function() { return "ABC"; };
        this.releaseItem12x = function(val) {
          _released_item12x = val;    // not called
        };
      });
      var out = new oktest.util.StringIO();
      t12.run({out:out, color:false});
      assert.match(out.value(), /passed:1, failed:0, error:0/);
      assert.equal(_released_item12x, null);
      assert.equal(_released_item12y, null);
    },
    ////
    "dependency between fixtures are resolved automatically.": function(topic) {
      var _provided_a = null;
      var t21 = oktest.create();
      t21.topic("outer21", function() {
        this.provideA   = function(b, d) { return b + d + "<A>"; };
        this.provideB   = function(c)    { return c + "<B>"; };
        this.provideC   = function()     { return "<C>"; };
        t21.topic("inner21", function() {
          this.provideD = function(e)    { return e + "<D>"; };
          this.provideE = function()     { return "<E>"; };
          t21.spec("dependency is resolved.", function(a) {
            assert.equal(a, "<C><B><E><D><A>");
            _provided_a = a;
          });
        });
      });
      var out = new oktest.util.StringIO();
      t21.run({out:out, color:false});
      assert.match(out.value(), /passed:1, failed:0, error:0/);
      assert.equal(_provided_a, "<C><B><E><D><A>");
    },
    ////
    "looped dependency is reported as error.": function(topic) {
      var _called = false;
      var t22 = oktest.create();
      t22.topic("outer22", function() {
        this.provideA   = function(b, d) { return b + d + "<A>"; };
        this.provideB   = function(c)    { return c + "<B>"; };
        this.provideC   = function(e)    { return e + "<C>"; };
        t22.topic("inner22", function() {
          this.provideD = function(b)    { return b + "<D>"; };
          this.provideE = function(d)    { return d + "<E>"; };
          t22.spec("spec#22", function(a) {
            _called = true;   // not reached
          });
        });
      });
      var out = new oktest.util.StringIO();
      t22.run({out:out, color:false});
      assert.match(out.value(), /passed:0, failed:0, error:1/);
      assert.match(out.value(), /Error: fixture dependency is looped: a->b=>c=>e=>d=>b \(topic: inner22, spec: spec#22\)/);
      assert.equal(_called, false);
    },
    ////
    "looped dependency is reported as error.": function(topic) {
      var _called = false;
      var t22 = oktest.create();
      t22.topic("outer22", function() {
        this.provideA   = function(b, d) { return b + d + "<A>"; };
        this.provideB   = function(c)    { return c + "<B>"; };
        this.provideC   = function(e)    { return e + "<C>"; };
        t22.topic("inner22", function() {
          this.provideD = function(b)    { return b + "<D>"; };
          this.provideE = function(d)    { return d + "<E>"; };
          t22.spec("spec#22", function(a) {
            _called = true;   // not reached
          });
        });
      });
      var out = new oktest.util.StringIO();
      t22.run({out:out, color:false});
      assert.match(out.value(), /passed:0, failed:0, error:1/);
      assert.match(out.value(), /Error: fixture dependency is looped: a->b=>c=>e=>d=>b \(topic: inner22, spec: spec#22\)/);
      assert.equal(_called, false);
    },
    ////
    "looped dependency is reported as error.": function(topic) {
      var _called = false;
      var t22 = oktest.create();
      t22.topic("outer22", function() {
        this.provideA   = function(b, d) { return b + d + "<A>"; };
        this.provideB   = function(c)    { return c + "<B>"; };
        this.provideC   = function(e)    { return e + "<C>"; };
        t22.topic("inner22", function() {
          this.provideD = function(b)    { return b + "<D>"; };
          this.provideE = function(d)    { return d + "<E>"; };
          t22.spec("spec#22", function(a) {
            _called = true;   // not reached
          });
        });
      });
      var out = new oktest.util.StringIO();
      t22.run({out:out, color:false});
      assert.match(out.value(), /passed:0, failed:0, error:1/);
      assert.match(out.value(), /Error: fixture dependency is looped: a->b=>c=>e=>d=>b \(topic: inner22, spec: spec#22\)/);
      assert.equal(_called, false);
    },
    ////
    "arguments starting with '_' are not regareded as fixtures.": function(topic) {
      var t23 = oktest.create();
      t23.topic("outer23", function() {
        this.provideItem23 = function(_foo) { return "<"+_foo+">"; };
        t23.topic("inner23", function() {
          t23.spec("'_foo' is not a fixture.", function(item23) {
            assert.equal(item23, "<undefined>");
          });
        });
      });
      var out = new oktest.util.StringIO();
      t23.run({out:out, color:false});
      assert.match(out.value(), /passed:1, failed:0, error:0/);
    },
    ////
    "optional values specified on spec are passed into providers.": function(topic) {
      var t24 = oktest.create();
      t24.topic("outer24", function() {
        this.provideItem24 = function(_foo) { return "<"+_foo+">"; };
        t24.topic("inner24", function() {
          t24.spec("default value is passed into provider.", {_foo:"abc"}, function(item24) {
            assert.equal(item24, "<abc>");
          });
        });
      });
      var out = new oktest.util.StringIO();
      t24.run({out:out, color:false});
      assert.match(out.value(), /passed:1, failed:0, error:0/);
    },
    ////
    "cleaner fixture cleans up regsitered files at the end of spec.": function(topic) {
      var t31 = oktest.create();
      oktest.config.debug = true;
      t31.topic("topic31", function() {
        t31.spec("cleaner is provided.", function(cleaner) {
          assert.instanceOf(cleaner, oktest.fixture.Cleaner);
          cleaner.add("__t1.txt", "__t2.dir");
          _createDummyFile("__t1.txt", "__t2.dir");
          shouldBeFile("__t1.txt");
          shouldBeDirectory("__t2.dir");
        });
      });
      var out = new oktest.util.StringIO();
      t31.run({out:out, color:false});
      assert.match(out.value(), /passed:1, failed:0, error:0/);
      //assert.throws(function() {fs.statSync("__t1.txt");}, Error);
      //assert.throws(function() {fs.statSync("__t2.dir");}, Error);
      shouldNotExist("__t1.txt");
      shouldNotExist("__t2.dir");
    },
    ////
    "cleaner fixture cleans up even when error thrown.": function(topic) {
      var t32 = oktest.create();
      oktest.config.debug = true;
      t32.topic("topic32", function() {
        t32.spec("cleaner is provided.", function(cleaner) {
          assert.instanceOf(cleaner, oktest.fixture.Cleaner);
          cleaner.add("__t1.txt", "__t2.dir");
          _createDummyFile("__t1.txt", "__t2.dir");
          shouldBeFile("__t1.txt");
          shouldBeDirectory("__t2.dir");
          ///
          throw Error("dummy");
        });
      });
      var out = new oktest.util.StringIO();
      t32.run({out:out, color:false});
      assert.match(out.value(), /passed:0, failed:0, error:1/);
      shouldNotExist("__t1.txt");
      shouldNotExist("__t2.dir");
    },
    ////
    "cleaner ignores unexisting files.": function(topic) {
      var t33 = oktest.create();
      oktest.config.debug = true;
      t33.topic("topic33", function() {
        t33.spec("cleaner is provided.", function(cleaner) {
          assert.instanceOf(cleaner, oktest.fixture.Cleaner);
          cleaner.add("__t1.txt", "__t2.dir");
          //_createDummyFile("__t1.txt", "__t2.dir");
          shouldNotExist("__t1.txt");
          shouldNotExist("__t2.dir");
        });
      });
      var out = new oktest.util.StringIO();
      t33.run({out:out, color:false});
      assert.match(out.value(), /passed:1, failed:0, error:0/);   /// NO ERROR!
    },
    ////
    null: function() {}
  }
//});
};


//if (process.argv[1] === __filename) {
//  suite.run();
//}
//else {
//  suite.export(module);     // allow vows command to execute this script
//}

if (require.main === module) {
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
  })(14);
}
