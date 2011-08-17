//var vows   = require("vows");
var assert = require("assert");
var fs     = require("fs");
var oktest = require("oktest");

var ok = oktest.ok;
var NG = oktest.NG;


function _doRun(engine, expected, opts) {
  var out = new oktest.util.StringIO();
  var kwargs = {out: out, color: true};
  if (! opts) opts = {};
  if ('color' in opts) kwargs.color = opts.color;
  if ('style' in opts) kwargs.style = opts.style;
  if ('out'   in opts) kwargs.out   = out = opts.out;
  engine.run(kwargs);
  if (kwargs.color)
    expected = oktest.util.Color._colorize(expected);
  var actual = out.value();
  actual = actual.replace(/\(in 0.\d\d\d?s\)/, '(in 0.000s)');
  actual = actual.replace(/(    at \S+ )\(.*?\brunner_test\.js/g, '$1(/tmp/runner_test.js');
  if (opts.output) {
    console.log();
    console.log(actual);
  }
  else {
    //if (actual !== expected && typeof(expected) === 'string') {
    //  fs.writeFileSync("_tmp.actual", actual, "utf8");
    //  fs.writeFileSync("_tmp.expected", expected, "utf8");
    //}
    ok (actual).eq(expected);
    assert.equal(actual, expected);
  }
}


function _do_test(desc, func) {
  console.log("x " + desc);
  func();
}

///
/// oktest.Runner.run()
///

_do_test("runs specs in topics.", function() {
  var t = oktest.create();
  t.topic("outer#1", function() {
    t.topic("middle#1-1", function() {
      t.spec("spec#1-1-1", function() {
        ok (1+1).eq(2);
      });
      t.spec("spec#1-1-2", function() {
        ok (1+1).eq(2);
      });
    });
    t.topic("middle#1-2", function() {
      t.topic("inner#1-2-1", function() {
        t.spec("spec#1-2-1-1", function() {
          ok (1+1).eq(2);
        });
        t.spec("spec#1-2-1-1", function() {
          ok (1+1).eq(2);
        });
      });
      t.topic("inner#1-2-2", function() {
        t.spec("spec#1-2-2-1", function() {
          ok (1+1).eq(2);
        });
        t.spec("spec#1-2-2-2", function() {
          ok (1+1).eq(2);
        });
      });
    });
  });
  t.topic("outer#2", function() {
    t.spec("spec#2-1", function() {
      ok (1+1).eq(2);
    });
  });
  var expected = (""
    //|* <b>outer#1</b>
    //|  * <b>middle#1-1</b>
    //|    - [<G>ok</G>] spec#1-1-1
    //|    - [<G>ok</G>] spec#1-1-2
    //|  * <b>middle#1-2</b>
    //|    * <b>inner#1-2-1</b>
    //|      - [<G>ok</G>] spec#1-2-1-1
    //|      - [<G>ok</G>] spec#1-2-1-1
    //|    * <b>inner#1-2-2</b>
    //|      - [<G>ok</G>] spec#1-2-2-1
    //|      - [<G>ok</G>] spec#1-2-2-2
    //|* <b>outer#2</b>
    //|  - [<G>ok</G>] spec#2-1
    //|## total:7, <G>passed:7</G>, failed:0, error:0, skipped:0  (in 0.000s)
    + '* <b>outer#1</b>\n'
    + '  * <b>middle#1-1</b>\n'
    + '    - [<G>ok</G>] spec#1-1-1\n'
    + '    - [<G>ok</G>] spec#1-1-2\n'
    + '  * <b>middle#1-2</b>\n'
    + '    * <b>inner#1-2-1</b>\n'
    + '      - [<G>ok</G>] spec#1-2-1-1\n'
    + '      - [<G>ok</G>] spec#1-2-1-1\n'
    + '    * <b>inner#1-2-2</b>\n'
    + '      - [<G>ok</G>] spec#1-2-2-1\n'
    + '      - [<G>ok</G>] spec#1-2-2-2\n'
    + '* <b>outer#2</b>\n'
    + '  - [<G>ok</G>] spec#2-1\n'
    + '## total:7, <G>passed:7</G>, failed:0, error:0, skipped:0  (in 0.000s)\n'
  );
  _doRun(t, expected);
});






/// line: 120
_do_test("reports failures and errors.", function() {
  var t = oktest.create();
  t.topic("outer#1", function() {
    t.topic("middle#1-1", function() {
      t.spec("spec#1-1-1", function() {
        ok (1+1).eq(2);
      });
      t.spec("spec#1-1-2", function() {
        ok (1+1).gt(3);   // failed
      });
      t.spec("spec#1-1-3", function() {
        var x = null;
        x.foobar();      // TypeError
      });
      t.spec("spec#1-1-4", function() {
        ok (1+1).eq(2);
      });
    });
    t.topic("middle#1-2", function() {
      t.spec("spec#1-2-1", function() {
        ok (1+1).eq(2);
      });
    });
  });
  var expected = (""
    //|* <b>outer#1</b>
    //|  * <b>middle#1-1</b>
    //|    - [<G>ok</G>] spec#1-1-1
    //|    - [<R>Failed</R>] spec#1-1-2
    //|    - [<R>ERROR</R>] spec#1-1-3
    //|    - [<G>ok</G>] spec#1-1-4
    //|<r>----------------------------------------------------------------------</r>
    //|[<R>Failed</R>] outer#1 > middle#1-1 > spec#1-1-2
    //|<R>AssertionError: $actual > $expected : failed.</R>
    //|  $actual  : 2
    //|  $expected: 3
    //|    at spec (/tmp/runner_test.js:129:18)
    //|        ok (1+1).gt(3);   // failed
    //|<r>----------------------------------------------------------------------</r>
    //|[<R>ERROR</R>] outer#1 > middle#1-1 > spec#1-1-3
    //|<R>TypeError: Cannot call method 'foobar' of null</R>
    //|    at spec (/tmp/runner_test.js:133:11)
    //|        x.foobar();      // TypeError
    //|<r>----------------------------------------------------------------------</r>
    //|  * <b>middle#1-2</b>
    //|    - [<G>ok</G>] spec#1-2-1
    //|## total:5, <G>passed:3</G>, <R>failed:1</R>, <R>error:1</R>, skipped:0  (in 0.000s)
    + '* <b>outer#1</b>\n'
    + '  * <b>middle#1-1</b>\n'
    + '    - [<G>ok</G>] spec#1-1-1\n'
    + '    - [<R>Failed</R>] spec#1-1-2\n'
    + '    - [<R>ERROR</R>] spec#1-1-3\n'
    + '    - [<G>ok</G>] spec#1-1-4\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '[<R>Failed</R>] outer#1 > middle#1-1 > spec#1-1-2\n'
    + '<R>AssertionError: $actual > $expected : failed.</R>\n'
    + '  $actual  : 2\n'
    + '  $expected: 3\n'
    + '    at spec (/tmp/runner_test.js:129:18)\n'
    + '        ok (1+1).gt(3);   // failed\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '[<R>ERROR</R>] outer#1 > middle#1-1 > spec#1-1-3\n'
    + '<R>TypeError: Cannot call method \'foobar\' of null</R>\n'
    + '    at spec (/tmp/runner_test.js:133:11)\n'
    + '        x.foobar();      // TypeError\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '  * <b>middle#1-2</b>\n'
    + '    - [<G>ok</G>] spec#1-2-1\n'
    + '## total:5, <G>passed:3</G>, <R>failed:1</R>, <R>error:1</R>, skipped:0  (in 0.000s)\n'
  );
  _doRun(t, expected, {output:0});
});







/// line: 200
_do_test("'style' option changes repoter class", function() {
  var t = oktest.create();
  t.topic("outer#1", function() {
    t.topic("middle#1-1", function() {
      t.spec("spec#1-1-1", function() {
        ok (1+1).eq(2);
      });
      t.spec("spec#1-1-2", function() {
        ok (1+1).gt(3);   // failed
      });
      t.spec("spec#1-1-3", function() {
        var x = null;
        x.foobar();      // TypeError
      });
      t.spec("spec#1-1-4", function() {
        ok (1+1).eq(2);
      });
    });
    t.topic("middle#1-2", function() {
      t.spec("spec#1-2-1", function() {
        ok (1+1).eq(2);
      });
    });
  });
  //// plain style
  var expected1 = (""
    //|.<R>f</R><R>E</R>.
    //|<r>----------------------------------------------------------------------</r>
    //|[<R>Failed</R>] outer#1 > middle#1-1 > spec#1-1-2
    //|<R>AssertionError: $actual > $expected : failed.</R>
    //|  $actual  : 2
    //|  $expected: 3
    //|    at spec (/tmp/runner_test.js:209:18)
    //|        ok (1+1).gt(3);   // failed
    //|<r>----------------------------------------------------------------------</r>
    //|[<R>ERROR</R>] outer#1 > middle#1-1 > spec#1-1-3
    //|<R>TypeError: Cannot call method 'foobar' of null</R>
    //|    at spec (/tmp/runner_test.js:213:11)
    //|        x.foobar();      // TypeError
    //|<r>----------------------------------------------------------------------</r>
    //|.
    //|## total:5, <G>passed:3</G>, <R>failed:1</R>, <R>error:1</R>, skipped:0  (in 0.000s)
    + '.<R>f</R><R>E</R>.\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '[<R>Failed</R>] outer#1 > middle#1-1 > spec#1-1-2\n'
    + '<R>AssertionError: $actual > $expected : failed.</R>\n'
    + '  $actual  : 2\n'
    + '  $expected: 3\n'
    + '    at spec (/tmp/runner_test.js:209:18)\n'
    + '        ok (1+1).gt(3);   // failed\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '[<R>ERROR</R>] outer#1 > middle#1-1 > spec#1-1-3\n'
    + '<R>TypeError: Cannot call method \'foobar\' of null</R>\n'
    + '    at spec (/tmp/runner_test.js:213:11)\n'
    + '        x.foobar();      // TypeError\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '.\n'
    + '## total:5, <G>passed:3</G>, <R>failed:1</R>, <R>error:1</R>, skipped:0  (in 0.000s)\n'
  );
  _doRun(t, expected1, {output:0, style:"plain"});
  //// simple style
  var expected2 = (""
    //|* <b>outer#1</b>: 
    //|  * <b>middle#1-1</b>: .<R>f</R><R>E</R>.
    //|<r>----------------------------------------------------------------------</r>
    //|[<R>Failed</R>] outer#1 > middle#1-1 > spec#1-1-2
    //|<R>AssertionError: $actual > $expected : failed.</R>
    //|  $actual  : 2
    //|  $expected: 3
    //|    at spec (/tmp/runner_test.js:209:18)
    //|        ok (1+1).gt(3);   // failed
    //|<r>----------------------------------------------------------------------</r>
    //|[<R>ERROR</R>] outer#1 > middle#1-1 > spec#1-1-3
    //|<R>TypeError: Cannot call method 'foobar' of null</R>
    //|    at spec (/tmp/runner_test.js:213:11)
    //|        x.foobar();      // TypeError
    //|<r>----------------------------------------------------------------------</r>
    //|  * <b>middle#1-2</b>: .
    //|## total:5, <G>passed:3</G>, <R>failed:1</R>, <R>error:1</R>, skipped:0  (in 0.000s)
    + '* <b>outer#1</b>: \n'
    + '  * <b>middle#1-1</b>: .<R>f</R><R>E</R>.\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '[<R>Failed</R>] outer#1 > middle#1-1 > spec#1-1-2\n'
    + '<R>AssertionError: $actual > $expected : failed.</R>\n'
    + '  $actual  : 2\n'
    + '  $expected: 3\n'
    + '    at spec (/tmp/runner_test.js:209:18)\n'
    + '        ok (1+1).gt(3);   // failed\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '[<R>ERROR</R>] outer#1 > middle#1-1 > spec#1-1-3\n'
    + '<R>TypeError: Cannot call method \'foobar\' of null</R>\n'
    + '    at spec (/tmp/runner_test.js:213:11)\n'
    + '        x.foobar();      // TypeError\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '  * <b>middle#1-2</b>: .\n'
    + '## total:5, <G>passed:3</G>, <R>failed:1</R>, <R>error:1</R>, skipped:0  (in 0.000s)\n'
  );
  _doRun(t, expected2, {output:0, style:"simple"});
});


















































//// line: 350
_do_test("before/after/beforeAll/afterAll are called if defined.", function() {
  var out = new oktest.util.StringIO();
  var t = oktest.create();
  t.topic("outer", function() {

    this.beforeAll = function() {  out.write("-- outer: beforeAll() called\n"); };
    this.afterAll  = function() {  out.write("-- outer: afterAll() called\n"); };
    this.before    = function() {  out.write("-- outer: before() called\n"); };
    this.after     = function() {  out.write("-- outer: after() called\n"); };

    t.topic("middle#1", function() {

      this.beforeAll = function() {  out.write("-- middle#1: beforeAll() called\n"); };
      this.afterAll  = function() {  out.write("-- middle#1: afterAll() called\n"); };
      this.before    = function() {  out.write("-- middle#1: before() called\n"); };
      this.after     = function() {  out.write("-- middle#1: after() called\n"); };

      t.spec("spec#1", function() {
        ok (1+1).eq(2);
      });
      t.spec("spec#2", function() {
        ok (1+1).gt(3);   // failed
      });
      t.spec("spec#3", function() {
        var x = null;
        x.foobar();      // TypeError
      });

    });

    t.topic("middle#2", function() {

      this.beforeAll = function() {  out.write("-- middle#2: beforeAll() called\n"); };
      this.afterAll  = function() {  out.write("-- middle#2: afterAll() called\n"); };
      this.before    = function() {  out.write("-- middle#2: before() called\n"); };
      this.after     = function() {  out.write("-- middle#2: after() called\n"); };

      t.spec("spec#4", function() {
        ok (1+1).eq(2);
      });

    });

  });
  ////
  var expected = (""
    //|* <b>outer</b>
    //|-- outer: beforeAll() called
    //|  * <b>middle#1</b>
    //|-- middle#1: beforeAll() called
    //|-- outer: before() called
    //|-- middle#1: before() called
    //|-- middle#1: after() called
    //|-- outer: after() called
    //|    - [<G>ok</G>] spec#1
    //|-- outer: before() called
    //|-- middle#1: before() called
    //|-- middle#1: after() called
    //|-- outer: after() called
    //|    - [<R>Failed</R>] spec#2
    //|-- outer: before() called
    //|-- middle#1: before() called
    //|-- middle#1: after() called
    //|-- outer: after() called
    //|    - [<R>ERROR</R>] spec#3
    //|-- middle#1: afterAll() called
    //|<r>----------------------------------------------------------------------</r>
    //|[<R>Failed</R>] outer > middle#1 > spec#2
    //|<R>AssertionError: $actual > $expected : failed.</R>
    //|  $actual  : 2
    //|  $expected: 3
    //|    at spec (/tmp/runner_test.js:372:18)
    //|        ok (1+1).gt(3);   // failed
    //|<r>----------------------------------------------------------------------</r>
    //|[<R>ERROR</R>] outer > middle#1 > spec#3
    //|<R>TypeError: Cannot call method 'foobar' of null</R>
    //|    at spec (/tmp/runner_test.js:376:11)
    //|        x.foobar();      // TypeError
    //|<r>----------------------------------------------------------------------</r>
    //|  * <b>middle#2</b>
    //|-- middle#2: beforeAll() called
    //|-- outer: before() called
    //|-- middle#2: before() called
    //|-- middle#2: after() called
    //|-- outer: after() called
    //|    - [<G>ok</G>] spec#4
    //|-- middle#2: afterAll() called
    //|-- outer: afterAll() called
    //|## total:4, <G>passed:2</G>, <R>failed:1</R>, <R>error:1</R>, skipped:0  (in 0.000s)
    + '* <b>outer</b>\n'
    + '-- outer: beforeAll() called\n'
    + '  * <b>middle#1</b>\n'
    + '-- middle#1: beforeAll() called\n'
    + '-- outer: before() called\n'
    + '-- middle#1: before() called\n'
    + '-- middle#1: after() called\n'
    + '-- outer: after() called\n'
    + '    - [<G>ok</G>] spec#1\n'
    + '-- outer: before() called\n'
    + '-- middle#1: before() called\n'
    + '-- middle#1: after() called\n'
    + '-- outer: after() called\n'
    + '    - [<R>Failed</R>] spec#2\n'
    + '-- outer: before() called\n'
    + '-- middle#1: before() called\n'
    + '-- middle#1: after() called\n'
    + '-- outer: after() called\n'
    + '    - [<R>ERROR</R>] spec#3\n'
    + '-- middle#1: afterAll() called\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '[<R>Failed</R>] outer > middle#1 > spec#2\n'
    + '<R>AssertionError: $actual > $expected : failed.</R>\n'
    + '  $actual  : 2\n'
    + '  $expected: 3\n'
    + '    at spec (/tmp/runner_test.js:372:18)\n'
    + '        ok (1+1).gt(3);   // failed\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '[<R>ERROR</R>] outer > middle#1 > spec#3\n'
    + '<R>TypeError: Cannot call method \'foobar\' of null</R>\n'
    + '    at spec (/tmp/runner_test.js:376:11)\n'
    + '        x.foobar();      // TypeError\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '  * <b>middle#2</b>\n'
    + '-- middle#2: beforeAll() called\n'
    + '-- outer: before() called\n'
    + '-- middle#2: before() called\n'
    + '-- middle#2: after() called\n'
    + '-- outer: after() called\n'
    + '    - [<G>ok</G>] spec#4\n'
    + '-- middle#2: afterAll() called\n'
    + '-- outer: afterAll() called\n'
    + '## total:4, <G>passed:2</G>, <R>failed:1</R>, <R>error:1</R>, skipped:0  (in 0.000s)\n'
  );
  _doRun(t, expected, {out:out});
});














//// line: 500
_do_test("show unified diff if texts are different.", function() {
  var out = new oktest.util.StringIO();
  var t = oktest.create();
  t.topic("topic1", function() {
    t.spec("shows unified diff", function() {
      var text1 = (""
        + "aaa\n"
        + "bbb\n"
        + "ccc\n"
        + "ddd\n"
        + "eee\n"
        + "fff\n"
        + "ggg\n"
        + "hhh1\n"
        + "iii1\n"
        + "jjj\n"
        + "kkk\n"
      );
      var text2 = (""
        + "aaa\n"
        + "bbb\n"
        + "ccc\n"
        + "ddd\n"
        + "eee\n"
        + "fff\n"
        + "ggg\n"
        + "hhh\n"
        + "iii2\n"
        + "jjj\n"
        + "kkk\n"
      );
      ok (text1).eq(text2);
    });
  });
  var expected = (""
    //|* <b>topic1</b>
    //|  - [<R>Failed</R>] shows unified diff
    //|<r>----------------------------------------------------------------------</r>
    //|[<R>Failed</R>] topic1 > shows unified diff
    //|<R>AssertionError: $actual == $expected : failed.</R>
    //|+++ $actual
    //|--- $expected
    //|@@ -5 +5
    //| eee
    //| fff
    //| ggg
    //|+hhh1
    //|+iii1
    //|-hhh
    //|-iii2
    //| jjj
    //| kkk
    //| 
    //|    at spec (/tmp/runner_test.js:532:18)
    //|        ok (text1).eq(text2);
    //|<r>----------------------------------------------------------------------</r>
    //|## total:1, passed:0, <R>failed:1</R>, error:0, skipped:0  (in 0.000s)
    + '* <b>topic1</b>\n'
    + '  - [<R>Failed</R>] shows unified diff\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '[<R>Failed</R>] topic1 > shows unified diff\n'
    + '<R>AssertionError: $actual == $expected : failed.</R>\n'
    + '+++ $actual\n'
    + '--- $expected\n'
    + '@@ -5 +5\n'
    + ' eee\n'
    + ' fff\n'
    + ' ggg\n'
    + '+hhh1\n'
    + '+iii1\n'
    + '-hhh\n'
    + '-iii2\n'
    + ' jjj\n'
    + ' kkk\n'
    + ' \n'
    + '    at spec (/tmp/runner_test.js:532:18)\n'
    + '        ok (text1).eq(text2);\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '## total:1, passed:0, <R>failed:1</R>, error:0, skipped:0  (in 0.000s)\n'
  );
  _doRun(t, expected);
});

















//// line: 600
_do_test("oktest.skip() skips test", function() {
  var t = oktest.create();
  t.topic("topic1", function() {
    t.spec("spec1-1", function() {
      oktest.skip("reason #1");
      throw new Error("not skipped");
    });
  });
  var expected = (""
    //|* <b>topic1</b>
    //|  - [<Y>skipped</Y>] spec1-1 (reason: reason #1)
    //|## total:1, passed:0, failed:0, error:0, <Y>skipped:1</Y>  (in 0.000s)
    + '* <b>topic1</b>\n'
    + '  - [<Y>skipped</Y>] spec1-1 (reason: reason #1)\n'
    + '## total:1, passed:0, failed:0, error:0, <Y>skipped:1</Y>  (in 0.000s)\n'
  );
  _doRun(t, expected);
});


_do_test("oktest.skipWhen() skips test when condition is true", function() {
  var t = oktest.create();
  t.topic("topic2", function() {
    t.spec("spec2", function() {
      oktest.skipWhen(1>0, "reason #2");
      throw new Error("not skipped");
    });
  });
  var expected = (""
    //|* <b>topic2</b>
    //|  - [<Y>skipped</Y>] spec2 (reason: reason #2)
    //|## total:1, passed:0, failed:0, error:0, <Y>skipped:1</Y>  (in 0.000s)
    + '* <b>topic2</b>\n'
    + '  - [<Y>skipped</Y>] spec2 (reason: reason #2)\n'
    + '## total:1, passed:0, failed:0, error:0, <Y>skipped:1</Y>  (in 0.000s)\n'
  );
  _doRun(t, expected);
});


_do_test("oktest.skipWhen() doesn't skip test when condition is false", function() {
  var t = oktest.create();
  t.topic("topic3", function() {
    t.spec("spec3", function() {
      oktest.skipWhen(1==0, "reason #3");
      ok (1+1).is(2);
    });
  });
  var expected = (""
    //|* <b>topic3</b>
    //|  - [<G>ok</G>] spec3
    //|## total:1, passed:0, failed:0, error:0, <Y>skipped:1</Y>  (in 0.000s)
    + '* <b>topic3</b>\n'
    + '  - [<G>ok</G>] spec3\n'
    + '## total:1, <G>passed:1</G>, failed:0, error:0, skipped:0  (in 0.000s)\n'
  );
  _doRun(t, expected);
});
