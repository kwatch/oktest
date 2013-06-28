# -*- coding: utf-8 -*-
###
### $Release: $
### $Copyright: copyright(c) 2010-2013 kuwata-lab.com all rights reserved $
### $License: MIT License $
###
#from __future__ import with_statement

import sys, os, re, shutil
sys.STDERR = sys.stderr

major, minor, teeny = sys.version_info[0:3]
py24 = major == 2 and minor <= 4
py25 = major == 2 and minor == 5
py26 = major == 2 and minor == 6
py27 = major == 2 and minor == 7
py30 = major == 3 and minor == 0
py31 = major == 3 and minor == 1
py32 = major == 3 and minor >= 2
#
py271 = major == 2 and minor == 7 and teeny <= 1
py314 = major == 3 and minor == 1 and teeny >= 4
py320 = major == 3 and minor == 2 and teeny <= 0
#
import unittest

import oktest
from oktest import ok, NG

try:
    from cStringIO import StringIO
except ImportError:
    from io import StringIO

from oktest.mainapp import MainApp
from oktest import config
from oktest.util import Color


HELP_MESSAGE = r"""
Usage: python -m oktest [options] file_or_directory...
  -h, --help          show help
  -v, --version       verion of oktest.py
  -s STYLE            reporting style (plain/simple/verbose, or p/s/v)
  --color=true|false  enable/disable output color
  -K ENCODING         output encoding (utf-8 when system default is US-ASCII)
  -p PAT[,PAT2,..]    test script pattern (default '*_test.py,test_*.py')
  -U                  run testcases with unittest.main instead of oktest.run
  -D                  debug mode
  -f FILTER           filter (class=xxx/test=xxx/useroption=xxx)
Example:
   ## run test scripts in plain format
   $ python -m oktest -sp tests/*_test.py
   ## run test scripts in 'tests' dir with pattern '*_test.py'
   $ python -m oktest -p '*_test.py' tests
   ## filter by class name
   $ python -m oktest -f class='ClassName*' tests
   ## filter by test method name
   $ python -m oktest -f '*method*' tests   # or -f test='*method*'
   ## filter by user-defined option added by @test decorator
   $ python -m oktest -f tag='*value*' tests

"""[1:]


INPUT_CODE = r"""
import sys, unittest
import oktest
from oktest import ok, NG, test, fail, skip, todo

class SosTest(unittest.TestCase):
    # passed
    @test("1+1 should be 2", tag='tag1')
    def _(self):
        ok (1+1) == 2
    # failed
    @test("1-1 should be 0", tag='tag2')
    def _(self):
        ok (1-1) == 2
    # error
    @test("should raise NameError")
    def _(self):
        [].sos
    # skip
    @test("never done")
    @skip.when(1==1, "REASON")
    def _(self):
        sys.exit()
    # todo
    @test("not yet")
    @todo
    def _(self):
        fail("msg")

class Sos_TC(unittest.TestCase):
    def test_aaa(self):
      ok ("aaa") == "aaa"
    def test_bbb(self):
      ok ("bbb") == "aaa"

if __name__ == "__main__":
    oktest.main()
"""


OUTPUT_ERRORS1 = r"""
<r>----------------------------------------------------------------------</r>
[<R>Fail</R>] SosTest > 002: 1-1 should be 0
  File "_test.d/_sos_test.py", line 14, in _
    ok (1-1) == 2
<R>AssertionError: 0 == 2 : failed.</R>
<r>----------------------------------------------------------------------</r>
[<R>ERROR</R>] SosTest > 003: should raise NameError
  File "_test.d/_sos_test.py", line 18, in _
    [].sos
<R>AttributeError: 'list' object has no attribute 'sos'</R>
<r>----------------------------------------------------------------------</r>
"""[1:]

OUTPUT_ERRORS2 = r"""
<r>----------------------------------------------------------------------</r>
[<R>Fail</R>] Sos_TC > test_bbb()
  File "_test.d/_sos_test.py", line 34, in test_bbb
    ok ("bbb") == "aaa"
<R>AssertionError: 'bbb' == 'aaa' : failed.</R>
--- expected 
+++ actual 
@@ -1,1 +1,1 @@
-aaa
+bbb
<r>----------------------------------------------------------------------</r>
"""[1:]

if py27 or py314 or py32:
    OUTPUT_ERRORS2 = r"""
<r>----------------------------------------------------------------------</r>
[<R>Fail</R>] Sos_TC > test_bbb()
  File "_test.d/_sos_test.py", line 34, in test_bbb
    ok ("bbb") == "aaa"
<R>AssertionError: 'bbb' == 'aaa' : failed.</R>
--- expected
+++ actual
@@ -1 +1 @@
-aaa
+bbb
<r>----------------------------------------------------------------------</r>
"""[1:]
    if py271 or py320:
        OUTPUT_ERRORS2 = OUTPUT_ERRORS2.replace('@@ -1 +1 @@', '@@ -1,1 +1,1 @@')


OUTPUT_FOOTER = r"""
## total:7, <G>pass:2</G>, <R>fail:2</R>, <R>error:1</R>, <Y>skip:1</Y>, <Y>todo:1</Y>  (0.000 sec)
"""[1:]


OUTPUT_VERBOSE_BASE = r"""
* <b>SosTest</b>
  - [<G>pass</G>] 1+1 should be 2
  - [<R>Fail</R>] 1-1 should be 0
  - [<R>ERROR</R>] should raise NameError
  - [<Y>skip</Y>] never done (reason: REASON)
  - [<Y>TODO</Y>] not yet
"""[1:] + OUTPUT_ERRORS1 + r"""
* <b>Sos_TC</b>
  - [<G>pass</G>] test_aaa
  - [<R>Fail</R>] test_bbb
"""[1:] + OUTPUT_ERRORS2 + OUTPUT_FOOTER

OUTPUT_SIMPLE_BASE = r"""
* <b>SosTest</b>: .<R>f</R><R>E</R><Y>s</Y><Y>t</Y>
"""[1:] + OUTPUT_ERRORS1 + r"""
* <b>Sos_TC</b>: .<R>f</R>
"""[1:] + OUTPUT_ERRORS2 + OUTPUT_FOOTER

OUTPUT_PLAIN_BASE = r"""
.<R>f</R><R>E</R><Y>s</Y><Y>t</Y>
"""[1:] + OUTPUT_ERRORS1 + r"""
.<R>f</R>
"""[1:] + OUTPUT_ERRORS2 + "\n" + OUTPUT_FOOTER

OUTPUT_VERBOSE = Color._colorize(OUTPUT_VERBOSE_BASE)
OUTPUT_SIMPLE  = Color._colorize(OUTPUT_SIMPLE_BASE)
OUTPUT_PLAIN   = Color._colorize(OUTPUT_PLAIN_BASE)


OUTPUT_COLORED = Color._colorize(OUTPUT_VERBOSE_BASE)
OUTPUT_MONO    = re.sub(r'</?[brRGY]>', '', OUTPUT_VERBOSE_BASE)


OUTPUT_UNITTEST = r"""
.FEEE.F
======================================================================
ERROR: should raise NameError
----------------------------------------------------------------------
Traceback (most recent call last):
  File "_test.d/_sos_test.py", line 18, in _
    [].sos
AttributeError: 'list' object has no attribute 'sos'

======================================================================
ERROR: never done
----------------------------------------------------------------------
SkipTest: REASON

======================================================================
ERROR: not yet
----------------------------------------------------------------------
_ExpectedFailure: expected failure

======================================================================
FAIL: 1-1 should be 0
----------------------------------------------------------------------
Traceback (most recent call last):
  File "_test.d/_sos_test.py", line 14, in _
    ok (1-1) == 2
AssertionError: 0 == 2 : failed.

======================================================================
FAIL: test_bbb (_sos_test.Sos_TC)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "_test.d/_sos_test.py", line 34, in test_bbb
    ok ("bbb") == "aaa"
AssertionError: 'bbb' == 'aaa' : failed.
--- expected 
+++ actual 
@@ -1,1 +1,1 @@
-aaa
+bbb


----------------------------------------------------------------------
Ran 7 tests in 0.000s

FAILED (failures=2, errors=3)
"""[1:]

if py27 or py32:
    OUTPUT_UNITTEST = r"""
.FEsx.F
======================================================================
ERROR: test_003: should raise NameError (_sos_test.SosTest)
should raise NameError
----------------------------------------------------------------------
Traceback (most recent call last):
  File "_test.d/_sos_test.py", line 18, in _
    [].sos
AttributeError: 'list' object has no attribute 'sos'

======================================================================
FAIL: test_002: 1-1 should be 0 (_sos_test.SosTest)
1-1 should be 0
----------------------------------------------------------------------
Traceback (most recent call last):
  File "_test.d/_sos_test.py", line 14, in _
    ok (1-1) == 2
AssertionError: 0 == 2 : failed.

======================================================================
FAIL: test_bbb (_sos_test.Sos_TC)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "_test.d/_sos_test.py", line 34, in test_bbb
    ok ("bbb") == "aaa"
AssertionError: 'bbb' == 'aaa' : failed.
--- expected
+++ actual
@@ -1 +1 @@
-aaa
+bbb


----------------------------------------------------------------------
Ran 7 tests in 0.000s

FAILED (failures=2, errors=1, skipped=1, expected failures=1)
"""[1:]
    if py271 or py320:
        OUTPUT_UNITTEST = OUTPUT_UNITTEST.replace('@@ -1 +1 @@', '@@ -1,1 +1,1 @@')

if py30:
    OUTPUT_UNITTEST = r"""
.FEEE.F
======================================================================
ERROR: should raise NameError
----------------------------------------------------------------------
Traceback (most recent call last):
  File "_test.d/_sos_test.py", line 18, in _
    [].sos
AttributeError: 'list' object has no attribute 'sos'

======================================================================
ERROR: never done
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/usr/local/lib/python/unittest.py", line 254, in run
    testMethod()
  File "/usr/local/lib/python/site-packages/oktest.py", line 1931, in newfunc
    return orig_func(self)
  File "/usr/local/lib/python/site-packages/oktest.py", line 565, in fn
    raise SkipTest(reason)
oktest.SkipTest: REASON

======================================================================
ERROR: not yet
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/usr/local/lib/python/site-packages/oktest.py", line 586, in deco
    func(*args, **kwargs)
  File "_test.d/_sos_test.py", line 28, in _
    fail("msg")
  File "/usr/local/lib/python/site-packages/oktest.py", line 499, in fail
    raise AssertionError(desc)
AssertionError: msg

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/usr/local/lib/python/unittest.py", line 254, in run
    testMethod()
  File "/usr/local/lib/python/site-packages/oktest.py", line 1931, in newfunc
    return orig_func(self)
  File "/usr/local/lib/python/site-packages/oktest.py", line 589, in deco
    raise _ExpectedFailure(sys.exc_info())
oktest._ExpectedFailure: expected failure

======================================================================
FAIL: 1-1 should be 0
----------------------------------------------------------------------
Traceback (most recent call last):
  File "_test.d/_sos_test.py", line 14, in _
    ok (1-1) == 2
AssertionError: 0 == 2 : failed.

======================================================================
FAIL: test_bbb (_sos_test.Sos_TC)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "_test.d/_sos_test.py", line 34, in test_bbb
    ok ("bbb") == "aaa"
AssertionError: 'bbb' == 'aaa' : failed.
--- expected 
+++ actual 
@@ -1,1 +1,1 @@
-aaa
+bbb


----------------------------------------------------------------------
Ran 7 tests in 0.000s

FAILED (failures=2, errors=3)
"""[1:]

if py31:
    OUTPUT_UNITTEST = r"""
.FEsE.F
======================================================================
ERROR: test_003: should raise NameError (_sos_test.SosTest)
should raise NameError
----------------------------------------------------------------------
Traceback (most recent call last):
  File "_test.d/_sos_test.py", line 18, in _
    [].sos
AttributeError: 'list' object has no attribute 'sos'

======================================================================
ERROR: test_005: not yet (_sos_test.SosTest)
not yet
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/usr/local/lib/python/site-packages/oktest.py", line 586, in deco
    func(*args, **kwargs)
  File "_test.d/_sos_test.py", line 28, in _
    fail("msg")
  File "/usr/local/lib/python/site-packages/oktest.py", line 499, in fail
    raise AssertionError(desc)
AssertionError: msg

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/usr/local/lib/python/unittest.py", line 480, in run
    testMethod()
  File "/usr/local/lib/python/site-packages/oktest.py", line 1931, in newfunc
    return orig_func(self)
  File "/usr/local/lib/python/site-packages/oktest.py", line 589, in deco
    raise _ExpectedFailure(sys.exc_info())
oktest._ExpectedFailure: expected failure

======================================================================
FAIL: test_002: 1-1 should be 0 (_sos_test.SosTest)
1-1 should be 0
----------------------------------------------------------------------
Traceback (most recent call last):
  File "_test.d/_sos_test.py", line 14, in _
    ok (1-1) == 2
AssertionError: 0 == 2 : failed.

======================================================================
FAIL: test_bbb (_sos_test.Sos_TC)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "_test.d/_sos_test.py", line 34, in test_bbb
    ok ("bbb") == "aaa"
AssertionError: 'bbb' == 'aaa' : failed.
--- expected 
+++ actual 
@@ -1,1 +1,1 @@
-aaa
+bbb


----------------------------------------------------------------------
Ran 7 tests in 0.000s

FAILED (failures=2, errors=2, skipped=1)
"""[1:]
    if py314:
        OUTPUT_UNITTEST = OUTPUT_UNITTEST.replace('@@ -1,1 +1,1 @@', '@@ -1 +1 @@')
        OUTPUT_UNITTEST = OUTPUT_UNITTEST.replace('--- expected ', '--- expected')
        OUTPUT_UNITTEST = OUTPUT_UNITTEST.replace('+++ actual ', '+++ actual')
        OUTPUT_UNITTEST = OUTPUT_UNITTEST.replace(' line 480,', ' line 483,')



class OktestMainApp_TC(unittest.TestCase):

    def setUp(self):
        input = INPUT_CODE
        dir = "_test.d"
        os.mkdir(dir)
        filename = dir + "/_sos_test.py"
        f = open(filename, 'w'); f.write(input); f.close()
        self.cleaner = [dir]
        self.dirname = dir

    def tearDown(self):
        for fname in self.cleaner:
            if os.path.isfile(fname):
                os.unlink(fname)
            elif os.path.isdir(fname):
                shutil.rmtree(fname)

    def _run_app(self, *args):
        sys_argv = [__file__, self.dirname]
        sys_argv.extend(args)
        sout = serr = None
        ex = None
        config_dict = config.__dict__.copy()
        try:
            bkup = (sys.stdout, sys.stderr)
            sys.stdout = StringIO()
            sys.stderr = StringIO()
            try:
                MainApp.main(sys_argv)
            finally:
                sout = sys.stdout.getvalue()
                serr = sys.stderr.getvalue()
                sys.stdout, sys.stderr = bkup
                for k in config_dict:
                    setattr(config, k, config_dict[k])
        except SystemExit:
            ex = sys.exc_info()[1]
        except Exception:
            ex = sys.exc_info()[1]
        return sout, serr, ex

    def _chk(self, expecteds, actuals):
        expected_sout, expected_serr, expected_status = expecteds
        sout, serr, ex = actuals
        sout = re.sub(r'\(\d\.\d\d\d sec\)', '(0.000 sec)', sout) # for oktest
        serr = re.sub(r' in \d\.\d\d\ds', ' in 0.000s', serr)     # for unittest
        unittest_py_path = '/usr/local/lib/python/unittest.py'
        oktest_py_path   = '/usr/local/lib/python/site-packages/oktest.py'
        #sout = re.sub(r'File ".*/oktest.py", line',   'File "%s", line' % oktest_py_path, sout)
        sout = re.sub(r'File ".*/unittest\.py", line', 'File "%s", line' % unittest_py_path, sout)
        serr = re.sub(r'File ".*/oktest\.py", line',   'File "%s", line' % oktest_py_path, serr)
        serr = re.sub(r'File ".*/unittest\.py", line', 'File "%s", line' % unittest_py_path, serr)
        self.maxDiff = None
        if hasattr(self, 'assertMultiLineEqual'):
            self.assertMultiLineEqual(expected_serr, serr)
            self.assertMultiLineEqual(expected_sout, sout)
        else:
            ok (serr) == expected_serr
            ok (sout) == expected_sout
            self.assertEqual(expected_serr, serr)
            self.assertEqual(expected_sout, sout)
        if hasattr(self, 'assertIsInstance'):
            self.assertIsInstance(ex, SystemExit)
        else:
            self.assertTrue(isinstance(ex, SystemExit), "SystemExit expected but got %r" % ex)
        self.assertEqual(expected_status, ex.code)

    def _modify(self, expected, _sys_argv0=sys.argv[0]):
        basename = os.path.basename(_sys_argv0)
        expected = expected.replace('mainapp_test.py', basename)
        if py24:
            expected = expected.replace('Usage:', 'usage:')
        return expected


    def test_main__help(self):
        expected = HELP_MESSAGE
        #
        sout, serr, ex = self._run_app('-h')
        self._chk((expected, "", None), (sout, serr, ex))
        #
        sout, serr, ex = self._run_app('--help')
        self._chk((expected, "", None), (sout, serr, ex))


    def test_main__version(self):
        expected = ''.join((
            "oktest: %s\n" % oktest.__version__,
            "python: %s\n\n" % (sys.version.split("\n")[0]),
            ))
        #
        sout, serr, ex = self._run_app('-v')
        self._chk((expected, "", None), (sout, serr, ex))
        #
        sout, serr, ex = self._run_app('--version')
        self._chk((expected, "", None), (sout, serr, ex))


    def test_main__output(self):
        expected = OUTPUT_MONO
        #
        sout, serr, ex = self._run_app()
        self._chk((expected, "", 3), (sout, serr, ex))


    def test_main__color(self):
        expected = OUTPUT_COLORED
        #
        sout, serr, ex = self._run_app('--color=true')
        self._chk((expected, "", 3), (sout, serr, ex))
        #
        sout, serr, ex = self._run_app('--color=yes')
        self._chk((expected, "", 3), (sout, serr, ex))
        #
        sout, serr, ex = self._run_app('--color=on')
        self._chk((expected, "", 3), (sout, serr, ex))


    def test_main__color__error(self):
        expected = r"""
Usage: mainapp_test.py [options]

mainapp_test.py: error: --color='True': 'true' or 'false' expected
"""[1:]
        expected = self._modify(expected)
        #
        sout, serr, ex = self._run_app('--color=True')
        self._chk(("", expected, 2), (sout, serr, ex))


    def test_main__style_verbose(self):
        expected = OUTPUT_VERBOSE
        #
        sout, serr, ex = self._run_app('-s', 'verbose', '--color=true')
        self._chk((expected, "", 3), (sout, serr, ex))
        #
        sout, serr, ex = self._run_app('-sv', '--color=true')
        self._chk((expected, "", 3), (sout, serr, ex))


    def test_main__style_simple(self):
        expected = OUTPUT_SIMPLE
        #
        sout, serr, ex = self._run_app('-s', 'simple', '--color=true')
        self._chk((expected, "", 3), (sout, serr, ex))
        #
        sout, serr, ex = self._run_app('-ss', '--color=true')
        self._chk((expected, "", 3), (sout, serr, ex))


    def test_main__style_plain(self):
        expected = OUTPUT_PLAIN
        #
        sout, serr, ex = self._run_app('-s', 'plain', '--color=true')
        self._chk((expected, "", 3), (sout, serr, ex))
        #
        sout, serr, ex = self._run_app('-sp', '--color=true')
        self._chk((expected, "", 3), (sout, serr, ex))


    def test_main__style__error_1(self):
        expected = r"""
Usage: mainapp_test.py [options]

mainapp_test.py: error: -s option requires an argument
"""[1:]
        expected = self._modify(expected)
        #
        sout, serr, ex = self._run_app('-s')
        self._chk(("", expected, 2), (sout, serr, ex))


    def test_main__style__error_2(self):
        expected = r"""
Usage: mainapp_test.py [options]

mainapp_test.py: error: 'default': unknown report sytle (plain/simple/verbose, or p/s/v)
"""[1:]
        expected = self._modify(expected)
        #
        sout, serr, ex = self._run_app('-s', 'default')
        self._chk(("", expected, 2), (sout, serr, ex))


    def test_main__pattern(self):
        expected = r"""
## total:0, pass:0, fail:0, error:0, skip:0, todo:0  (0.000 sec)
"""[1:]
        #
        sout, serr, ex = self._run_app('-p', 'test_*.py', '--color=true')
        self._chk((expected, "", 0), (sout, serr, ex))
        #
        expected = OUTPUT_COLORED
        #
        sout, serr, ex = self._run_app('-p', '*_test.py', '--color=true')
        self._chk((expected, "", 3), (sout, serr, ex))


    def test_main__pattern__error(self):
        expected = r"""
Usage: mainapp_test.py [options]

mainapp_test.py: error: -p option requires an argument
"""[1:]
        expected = self._modify(expected)
        #
        sout, serr, ex = self._run_app('-p')
        self._chk(("", expected, 2), (sout, serr, ex))


    def test_main__unittest(self):
        expected_serr = OUTPUT_UNITTEST
        expected_sout = ""
        #
        sout, serr, ex = self._run_app('-U')
        n = (py27 and 3) or (py31 and 4) or (py32 and 3) or 5
        self._chk((expected_sout, expected_serr, n), (sout, serr, ex))


    def test_main__filter__class(self):
        expected = r"""
* <b>Sos_TC</b>
  - [<G>pass</G>] test_aaa
  - [<R>Fail</R>] test_bbb
"""[1:] + OUTPUT_ERRORS2 + r"""
## total:2, <G>pass:1</G>, <R>fail:1</R>, error:0, skip:0, todo:0  (0.000 sec)
"""[1:]
        expected = Color._colorize(expected)
        #
        sout, serr, ex = self._run_app('-f', 'class=*_TC', '--color=true')
        self._chk((expected, "", 1), (sout, serr, ex))


    def test_main__filter__test(self):
        expected = r"""
* <b>SosTest</b>
* <b>Sos_TC</b>
  - [<G>pass</G>] test_aaa
## total:1, <G>pass:1</G>, fail:0, error:0, skip:0, todo:0  (0.000 sec)
"""[1:]
        expected = Color._colorize(expected)
        #
        sout, serr, ex = self._run_app('-f', 'test=*aaa*', '--color=true')
        self._chk((expected, "", 0), (sout, serr, ex))
        #
        sout, serr, ex = self._run_app('-f', '*aaa*', '--color=true')
        self._chk((expected, "", 0), (sout, serr, ex))


    def test_main__filter__tag(self):
        expected = r"""
* <b>SosTest</b>
  - [<G>pass</G>] 1+1 should be 2
* <b>Sos_TC</b>
## total:1, <G>pass:1</G>, fail:0, error:0, skip:0, todo:0  (0.000 sec)
"""[1:]
        expected = Color._colorize(expected)
        #
        sout, serr, ex = self._run_app('-f', 'tag=tag1', '--color=true')
        self._chk((expected, "", 0), (sout, serr, ex))



if __name__ == '__main__':
    unittest.main()
