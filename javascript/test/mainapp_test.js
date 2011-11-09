//var vows   = require("vows");
var assert = require("assert");
var util   = require("util");
var fs     = require("fs");
var os     = require("os");
var oktest = require("oktest");

var ok = oktest.ok;
var NG = oktest.NG;


function _with_dummy_out(body) {
  var out = new oktest.util.StringIO();
  var bkup = util.print;
  util.print = function(arg) { out.write(arg); };
  try {
    body(out);
  }
  finally {
    util.print = bkup;
  }
}


function _with_dummy_write(body) {
  var bkup_write  = oktest.reporter.BaseReporter.prototype.write;
  var bkup_isatty = oktest.reporter.BaseReporter.prototype._isatty;
  oktest.reporter.BaseReporter.prototype.write = function write(arg) {
    if (arg) {
      //this.out.write(arg);
      util.print(arg);
      this._prev = arg;
    }
  };
  oktest.reporter.BaseReporter.prototype._isatty = function _isatty() {
    return false;
  };
  try {
    body();
  }
  finally {
    oktest.reporter.BaseReporter.prototype.write   = bkup_write;
    oktest.reporter.BaseReporter.prototype._isatty = bkup_isatty;
  }
}


function _with_dummy_dir(dirname, body) {
  try {
    fs.mkdirSync(dirname, 0755);
    body(dirname);
  }
  finally {
    oktest.util.rm_rf(dirname);
  }
}


function _with_dummy_file(filename, content, encoding, body) {
  if (typeof(encoding) == 'function') {
    body = encoding;
    encoding = 'utf8';
  }
  try {
    fs.writeFileSync(filename, content, encoding);
    body(filename);
  }
  finally {
    fs.unlinkSync(filename);
  }
}


var _count = 0;

function _doTest(spec, body) {
  oktest.shared.clear();
  try {
    var fname = '';
    _with_dummy_dir('_test.d', function() {
      _with_dummy_out(function(out) {
        _with_dummy_write(function() {
          //fname = '_test.d/sos_test.js';
          fname = '_test.d/sos_' + _count + '_test.js';  // enforce to be read by main()
          fs.writeFileSync(fname, INPUT, 'utf8');
          body(out, '_test.d');
        });
      });
    });
    assert.notEqual(fname, '');
    util.print('.');
  }
  catch (ex) {
    util.print("*** failed: '" + spec + "'\n");
    throw ex;
  }
  _count += 1;
}


var HELP_MESSAGE = (
  ''
    + 'Usage: node oktest.js [options] file [file2...]\n'
    + '  -h, --help    : show help\n'
    + '  -v, --version : version\n'
    + '  -s STYLE      : reporting style (verbose/simple/plain, or v/s/p)\n'
    + '  -p PATTERN    : file pattern to search (default \'*_test.js\')\n'
    + '  -f KEY=VAL    : filter topic or spec to run (see examples)\n'
    + '  -g            : generate template\n'
    + '  -c            : enable output colorize\n'
    + '  -C            : disable output colorize\n'
    + '  -D            : debug\n'
    + 'Example:\n'
    + '  ## run test scripts in plain format\n'
    + '  $ node oktest.js -sp tests/*_test.py\n'
    + '  ## run test scripts in \'tests\' dir with pattern \'*_test.py\'\n'
    + '  $ node oktest.js -p \'*_test.py\' tests\n'
    + '  ## filter by topic\n'
    + '  $ node oktest.js -f topic=\'*pattern*\' tests\n'
    + '  ## filter by spec\n'
    + '  $ node oktest.js -f \'*pattern*\' tests   # or -f spec=\'*pattern*\'\n'
);


var TEMPLATE = (
  ''
    + '"use strict";\n'
    + '//require.paths.push(".");   // or export $NODE_PATH=$PWD\n'
    + 'var oktest = require("oktest");\n'
    + 'var topic   = oktest.topic,\n'
    + '    spec    = oktest.spec,\n'
    + '    ok      = oktest.ok,\n'
    + '    NG      = oktest.NG,\n'
    + '    precond = oktest.precond;\n'
    + '\n'
    + '\n'
    + '+ topic("ClassName", function() {\n'
    + '\n'
    + '    + topic(".methodName()", function() {\n'
    + '\n'
    + '        - spec("description #1", function() {\n'
    + '              ok (1+1).is(2);\n'
    + '              ok (1+1, \'===\', 2);\n'
    + '          });\n'
    + '\n'
    + '        - spec("throws Error with error message", function() {\n'
    + '              function fn() { throw new Error("errmsg"); };\n'
    + '              ok (fn).throws_(Error, "errmsg");  // or ok (fn).throws(...)\n'
    + '              ok (fn.exception.message).match(/errmsg/);\n'
    + '          });\n'
    + '\n'
    + '        /// fixture injection example\n'
    + '\n'
    + '        this.provideYuki   = function() { return "Humanoid Interface"; };\n'
    + '        this.provideMikuru = function() { return "Time Traveler"; };\n'
    + '\n'
    + '        - spec("Yuki is a humanoid interface", function(yuki) {\n'
    + '              ok (yuki).is("Humanoid Interface");\n'
    + '          });\n'
    + '        - spec("Mikuru is a time traveler", function(mikuru) {\n'
    + '              ok (mikuru).is("Time Traveler");\n'
    + '          });\n'
    + '\n'
    + '      });\n'
    + '\n'
    + '  });\n'
    + '\n'
    + '\n'
    + 'if (require.main === module) {\n'
    + '    oktest.main();\n'
    + '}\n'
);


var INPUT = (
  ''
    + '"use strict";\n'
    + '\n'
    + 'var oktest = require("oktest");\n'
    + 'var topic   = oktest.topic,\n'
    + '    spec    = oktest.spec,\n'
    + '    ok      = oktest.ok,\n'
    + '    NG      = oktest.NG,\n'
    + '    skip    = oktest.skip,\n'
    + '    precond = oktest.precond;\n'
    + '\n'
    + 'topic("ClassName", function() {\n'
    + '\n'
    + '  topic("method1()", function() {\n'
    + '    spec("test_1", function() {   // passed\n'
    + '      ok (1+1).is(2);\n'
    + '    });\n'
    + '    spec("test_2", function() {   // failed\n'
    + '      ok (1+1).is(0);\n'
    + '    });\n'
    + '    spec("test_3", function() {   // error\n'
    + '      foobar();\n'
    + '    });\n'
    + '    spec("test_4", function() {   // skipped\n'
    + '      skip("REASON");\n'
    + '    });\n'
    + '  });\n'
    + '\n'
    + '  topic("method2()", function() {\n'
    + '    spec("test_aaa", function() { ok ("aaa").is("aaa"); });\n'
    + '    spec("test_bbb", function() { ok ("bbb").is("bbb"); });\n'
    + '  });\n'
    + '\n'
    + '});\n'
    + '\n'
    + 'if (require.main === module) { oktest.main(); }\n'
);

var OUTPUT_ERROR = (
  ''
    + '<r>----------------------------------------------------------------------</r>\n'
    + '[<R>Failed</R>] ClassName > method1() > test_2\n'
    + '<R>AssertionError: $actual === $expected : failed.</R>\n'
    + '  $actual  : 2\n'
    + '  $expected: 0\n'
    + '    at spec ($PWD/_test.d/sos_test.js:18:16)\n'
    + '        ok (1+1).is(0);\n'
    + '<r>----------------------------------------------------------------------</r>\n'
    + '[<R>ERROR</R>] ClassName > method1() > test_3\n'
    + '<R>ReferenceError: foobar is not defined</R>\n'
    + '    at spec ($PWD/_test.d/sos_test.js:21:7)\n'
    + '        foobar();\n'
    + '<r>----------------------------------------------------------------------</r>\n'
);

var OUTPUT_FOOTER = (
  ''
    + '## total:6, <G>passed:3</G>, <R>failed:1</R>, <R>error:1</R>, <Y>skipped:1</Y>  (in 0.000s)\n'
);


var OUTPUT_VERBOSE = (''
  + '* <b>ClassName</b>\n'
  + '  * <b>method1()</b>\n'
  + '    - [<G>ok</G>] test_1\n'
  + '    - [<R>Failed</R>] test_2\n'
  + '    - [<R>ERROR</R>] test_3\n'
  + '    - [<Y>skipped</Y>] test_4 (reason: REASON)\n'
) + OUTPUT_ERROR + (''
  + '  * <b>method2()</b>\n'
  + '    - [<G>ok</G>] test_aaa\n'
  + '    - [<G>ok</G>] test_bbb\n'
) + OUTPUT_FOOTER;

var OUTPUT_SIMPLE  = (''
  + '* <b>ClassName</b>: \n'
  + '  * <b>method1()</b>: .<R>f</R><R>E</R><Y>s</Y>\n'
) + OUTPUT_ERROR + (''
  + '  * <b>method2()</b>: ..\n'
) + OUTPUT_FOOTER;

var OUTPUT_PLAIN   = (''
  + '.<R>f</R><R>E</R><Y>s</Y>\n'
) + OUTPUT_ERROR + (''
  + '..\n'
) + OUTPUT_FOOTER;


var OUTPUT_BASE    = OUTPUT_VERBOSE;
var OUTPUT_COLORED = oktest.util.Color._colorize(OUTPUT_BASE);
var OUTPUT_MONO    = OUTPUT_BASE.replace(/<\/?[brRGY]>/g, '');


OUTPUT_VERBOSE = oktest.util.Color._colorize(OUTPUT_VERBOSE);
OUTPUT_SIMPLE  = oktest.util.Color._colorize(OUTPUT_SIMPLE);
OUTPUT_PLAIN   = oktest.util.Color._colorize(OUTPUT_PLAIN);


function _modify(str) {
  str = str.replace(/in \d\.\d\d\d?s/g, 'in 0.000s');
  str = str.replace(/at spec \(.*\/_test\.d\/sos_\d+_test\.js/g, 'at spec ($PWD/_test.d/sos_test.js');
  return str;
}


function _eq(actual, expected) {
  ok (actual).eq(expected);
  assert.equal(actual, expected);
}



///
/// -h: help message
///
_doTest("'-h' shows help message", function(out, testdir) {
  var expected = HELP_MESSAGE;
  oktest.main(['node', 'oktest.js', '-h']);
  _eq(out.output, expected);
});


///
/// -v: version
///
_doTest("'-v' shows version", function(out, testdir) {
  var expected = oktest.__version__ + "\n";
  oktest.main(['node', 'oktest.js', '-v']);
  _eq(out.output, expected);
});


///
/// -g: generate template
///
_doTest("'-g' generates template.", function(out, testdir) {
  var expected = TEMPLATE;
  oktest.main(['node', 'oktest.js', '-g']);
  _eq(out.output, expected);
});


///
/// prints result of testing
///
_doTest("prints result of testing.", function(out, testdir) {
  var win = os.type().match(/^win/i);
  var expected = win ? OUTPUT_MONO : OUTPUT_COLORED;
  oktest.main(['node', 'oktest.js', testdir]);
  _eq(_modify(out.output), expected);
});


///
/// -c: enable colorize
///
_doTest("-c: enable colorize.", function(out, testdir) {
  var expected = OUTPUT_COLORED;
  oktest.main(['node', 'oktest.js', '-c', testdir]);
  _eq(_modify(out.output), expected);
});


///
/// -C: disable colorize
///
_doTest("-C: disable colorize.", function(out, testdir) {
  var expected = OUTPUT_MONO;
  oktest.main(['node', 'oktest.js', '-C', testdir]);
  _eq(_modify(out.output), expected);
});


///
/// -s verbose
///
_doTest("-s verbose", function(out, testdir) {
  var expected = OUTPUT_VERBOSE;
  oktest.main(['node', 'oktest.js', '-s', 'verbose', testdir]);
  _eq(_modify(out.output), expected);
});
_doTest("-sv", function(out, testdir) {
  var expected = OUTPUT_VERBOSE;
  oktest.main(['node', 'oktest.js', '-sv', testdir]);
  _eq(_modify(out.output), expected);
});


///
/// -s simple
///
_doTest("-s simple", function(out, testdir) {
  var expected = OUTPUT_SIMPLE;
  oktest.main(['node', 'oktest.js', '-s', 'simple', testdir]);
  _eq(_modify(out.output), expected);
});
_doTest("-ss", function(out, testdir) {
  var expected = OUTPUT_SIMPLE;
  oktest.main(['node', 'oktest.js', '-ss', testdir]);
  _eq(_modify(out.output), expected);
});


///
/// -s plain
///
_doTest("-s plain", function(out, testdir) {
  var expected = OUTPUT_PLAIN;
  oktest.main(['node', 'oktest.js', '-s', 'plain', testdir]);
  _eq(_modify(out.output), expected);
});
_doTest("-sp", function(out, testdir) {
  var expected = OUTPUT_PLAIN;
  oktest.main(['node', 'oktest.js', '-sp', testdir]);
  _eq(_modify(out.output), expected);
});


///
/// -p pattern
///
_doTest("-p *_test.js", function(out, testdir) {
  var expected = OUTPUT_COLORED;
  oktest.main(['node', 'oktest.js', '-p', '*_test.js', testdir]);
  _eq(_modify(out.output), expected);
});
_doTest("-p test_*.js", function(out, testdir) {
  var expected = "## total:0, passed:0, failed:0, error:0, skipped:0  (in 0.000s)\n";
  oktest.main(['node', 'oktest.js', '-C', '-p', 'test_*.js', testdir]);
  _eq(_modify(out.output), expected);
});
_doTest("-p sos_*.js", function(out, testdir) {
  var expected = OUTPUT_MONO;
  oktest.main(['node', 'oktest.js', '-C', '-p', 'sos_*.js', testdir]);
  _eq(_modify(out.output), expected);
});


///
/// -f filter
///
_doTest("-f topic=method", function(out, testdir) {
  var expected = (
    ''
      + '* ClassName\n'
      + '  * method1()\n'
      + '  * method2()\n'
      + '    - [ok] test_aaa\n'
      + '    - [ok] test_bbb\n'
      + '## total:2, passed:2, failed:0, error:0, skipped:0  (in 0.000s)\n'
    );
  oktest.main(['node', 'oktest.js', '-C', '-f', 'topic=method2*', testdir]);
  _eq(_modify(out.output), expected);
});
_doTest("-f spec=*bbb", function(out, testdir) {
  var expected = (
    ''
      + '* ClassName\n'
      + '  * method1()\n'
      + '  * method2()\n'
      + '    - [ok] test_bbb\n'
      + '## total:1, passed:1, failed:0, error:0, skipped:0  (in 0.000s)\n'
    );
  oktest.main(['node', 'oktest.js', '-C', '-f', 'spec=*bbb', testdir]);
  _eq(_modify(out.output), expected);
});
_doTest("-f test_2", function(out, testdir) {
  var expected = (
    ''
      + 'f\n'
      + '----------------------------------------------------------------------\n'
      + '[Failed] ClassName > method1() > test_2\n'
      + 'AssertionError: $actual === $expected : failed.\n'
      + '  $actual  : 2\n'
      + '  $expected: 0\n'
      + '    at spec ($PWD/_test.d/sos_test.js:18:16)\n'
      + '        ok (1+1).is(0);\n'
      + '----------------------------------------------------------------------\n'
      + '## total:1, passed:0, failed:1, error:0, skipped:0  (in 0.000s)\n'
    );
  oktest.main(['node', 'oktest.js', '-C', '-sp', '-f', 'test_2', testdir]);
  _eq(_modify(out.output), expected);
});



///
/// end
///
util.print(" (" + _count + " tests)\n");
