# -*- coding: utf-8 -*-
###
### $Release: $
### $Copyright: copyright(c) 2010-2014 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest
try:
    from cStringIO import StringIO
except ImportError:
    from io import StringIO

import oktest
from oktest import ok, not_ok, NG, test, at_end
from oktest.dummy import dummy_io
from oktest.util import Color
from oktest.tracer import Tracer
import oktest.config

echo = sys.stdout.write
python_command = os.environ.get('PYTHON', 'python')
python24 = sys.version_info[0:2] <= (2, 4)
python33 = sys.version_info[0:2] == (3, 3)
def withstmt_not_available():
    if python24:
        sys.stderr.write("*** skip because with-statment is not supported\n")
        return True
    return False

prefix = "from __future__ import with_statement\nif True:\n"

def _exec_code(code):
    import unittest
    import oktest
    from oktest import ok, test
    from oktest.context import subject, situation
    lvars = {'unittest': unittest, 'oktest': oktest,
             'ok': ok, 'test': test, 'subject': subject,
             'situation': situation }
    exec(prefix + code, lvars, lvars)
    return lvars



class RunnerTestHelper(object):

    def _setUp(self):
        self.filename = '_test_.py'
        self._bkup = [sys.stdout, oktest.REPORTER, oktest.DIFF, oktest.config.color_enabled]
        sys.stdout = StringIO()
        oktest.REPORTER = oktest.OldStyleReporter
        oktest.config.color_enabled = True

    def _tearDown(self):
        sys.stdout, oktest.REPORTER, oktest.DIFF, oktest.config.color_enabled = self._bkup
        if os.path.exists(self.filename):
            os.unlink(self.filename)

    def do_test(self, desc, script, expected, callback=None, _pat=re.compile(r'0\.00[\d]s')):
        f = open(self.filename, 'w'); f.write(script); f.close()
        gvars = {}
        code = compile(script, self.filename, "exec")
        exec(code, gvars, gvars)
        output = sys.stdout.getvalue()
        #
        if isinstance(output, str):
            output = re.sub(r' at 0x[0-9a-f]{6,9}', '', output)
        if callback:
            output = callback(output)
        if python24:
            expected = expected.replace("failed, got ValueError('errmsg1',)", "failed, got <exceptions.ValueError instance>")
        if output == expected:
            self.assertEqual(expected, output)
        else:
            output   = re.sub(r'0\.00[\d]s', '0.000s', output)
            expected = expected.replace('--- expected ', '--- expected')
            expected = expected.replace('+++ actual ', '+++ actual')
            output   = output  .replace('--- expected ', '--- expected')
            output   = output  .replace('+++ actual ', '+++ actual')
            expected = expected.replace('@@ -1,1 +1,1 @@', '@@ -1 +1 @@')
            output   = output  .replace('@@ -1,1 +1,1 @@', '@@ -1 +1 @@')
            output   = re.sub(r'0\.0\d\d sec', '0.000 sec', output)
            #ver = sys.version_info[0:3]
            #if (2,7,2) <= ver < (3,2,0):
            #    expected = expected.replace('@@ -1,1 +1,1 @@', '@@ -1 +1 @@')
            #oktest.DIFF = repr
            ok (output) == expected
            try:
                self.assertEqual(expected, output)
            except AssertionError:
                if (isinstance(output, str) and isinstance(expected, str)):
                    import difflib
                    for x in difflib.unified_diff(expected.splitlines(True), output.splitlines(True), 'expected', 'actual', n=2):
                        echo(x)
                raise



class Runner_TC(unittest.TestCase, RunnerTestHelper):
    def setUp(self):    self._setUp()
    def tearDown(self): self._tearDown()


    def test_run_successful_script(self):
        desc = "successful script"
        script = r"""
from oktest import *
class FooTest(object):
    def test_plus(self):
        ok (1+1) == 2
run(FooTest)
"""
        expected = "* FooTest.test_plus ... [ok]\n"
        self.do_test(desc, script, expected)


    def test_run_failed_script(self):
        desc = "failed script"
        script = r"""
from oktest import *
class FooTest(object):
    def test_plus(self):
        ok (1+1) == 1
run(FooTest)
"""[1:]
        expected = r"""
* FooTest.test_plus ... [NG] 2 == 1 : failed.
   _test_.py:4: ok (1+1) == 1
"""[1:]
        self.do_test(desc, script, expected)


    def test_run_with_class_objects(self):
        desc = "run (with class objects)"
        script = r"""
from oktest import *
class FooTest(object):
    def test_1(self):
        ok (1+1) == 2
class BarTest(object):
    def test_2(self):
        ok (1+1) == 2
run(FooTest, BarTest)
"""[1:]
        expected = r"""
* FooTest.test_1 ... [ok]
* BarTest.test_2 ... [ok]
"""[1:]
        self.do_test(desc, script, expected)


    def test_run_with_pattern(self):
        desc = "run (with pattern)"
        script = r"""
from oktest import *
class FooTest(object):
    def test_1(self):
        ok (1+1) == 2
class BarTestCase(object):
    def test_2(self):
        ok (1+1) == 2
class BazTestCase(object):
    def test_3(self):
        ok (1+1) == 2
run('.*TestCase$')
"""[1:]
        expected = r"""
* BarTestCase.test_2 ... [ok]
* BazTestCase.test_3 ... [ok]
"""[1:]
        self.do_test(desc, script, expected)


    def test_before_after(self):
        desc = "before_all/before_each/after_each/after_all"
        script = r"""
from oktest import *
class FooTest(object):
    def before_all(cls):
        print('before_all() called.')
    before_all = classmethod(before_all)
    def after_all(cls):
        print('after_all() called.')
    after_all  = classmethod(after_all)
    def before(self):               # not called
        print('before() called.')
    def after(self):                # not called
        print('after() called.')
    #
    def test_1(self):
        print('test_1() called.')
        ok (1+1) == 2
    def test_2(self):
        print('test_2() called.')
        ok (1+1) == 3
    def test_3(self):
        print('test_3() called.')
        int('abc')
run('FooTest')
"""[1:]
        expected = r"""
before_all() called.
* FooTest.test_1 ... test_1() called.
[ok]
* FooTest.test_2 ... test_2() called.
[NG] 2 == 3 : failed.
   _test_.py:19: ok (1+1) == 3
* FooTest.test_3 ... test_3() called.
[ERROR] ValueError: invalid literal for int() with base 10: 'abc'
  - _test_.py:22:  int('abc')
after_all() called.
"""[1:]
        if python24:
            expected = expected.replace("int() with base 10: 'abc'", 'int(): abc')
        self.do_test(desc, script, expected)


    def test_when_error_raised_on_before_all(self):
        desc = "when error raised on before_all"
        script = r"""
from oktest import *
class FooTest(object):
    def before_all(cls):
        print('before_all() called.')
        "s".foobar   # AttributeError
    before_all = classmethod(before_all)
    def test_1(self):
        print('test_1() called.')
run('FooTest')
"""[1:]
        expected = r"""
before_all() called.
<r>----------------------------------------------------------------------</r>
[ERROR] FooTest > before_all()
  File "_test_.py", line 5, in before_all
    "s".foobar   # AttributeError
<R>AttributeError: 'str' object has no attribute 'foobar'</R>
<r>----------------------------------------------------------------------</r>
"""[1:]
        self.do_test(desc, script, Color._colorize(expected))


    def test_when_error_raised_on_after_all(self):
        desc = "when error raised on after_all"
        script = r"""
from oktest import *
class FooTest(object):
    def after_all(cls):
        print('after_all() called.')
        1 + "x"  # TypeError
    after_all = classmethod(after_all)
    def test_1(self):
        print('test_1() called.')
run('FooTest')
"""[1:]
        expected = r"""
* FooTest.test_1 ... test_1() called.
[ok]
after_all() called.
<r>----------------------------------------------------------------------</r>
[<R>ERROR</R>] FooTest > after_all()
  File "_test_.py", line 5, in after_all
    1 + "x"  # TypeError
<R>TypeError: unsupported operand type(s) for +: 'int' and 'str'</R>
<r>----------------------------------------------------------------------</r>
"""[1:]
        self.do_test(desc, script, Color._colorize(expected))


    def test_setup_teardown(self):
        desc = "setUp()/tearDown()"
        script = r"""
from oktest import *
class FooTest(object):
    def setUp(self):
        print('setUp() called.')
    def tearDown(self):
        print('tearDown() called.')
    #
    def test_1(self):
        print('test_1() called.')
        ok (1+1) == 2
    def test_2(self):
        print('test_2() called.')
        ok (1+1) == 3
    def test_3(self):
        print('test_3() called.')
        int('abc')
run('FooTest')
"""[1:]
        expected = r"""
* FooTest.test_1 ... setUp() called.
test_1() called.
tearDown() called.
[ok]
* FooTest.test_2 ... setUp() called.
test_2() called.
tearDown() called.
[NG] 2 == 3 : failed.
   _test_.py:13: ok (1+1) == 3
* FooTest.test_3 ... setUp() called.
test_3() called.
tearDown() called.
[ERROR] ValueError: invalid literal for int() with base 10: 'abc'
  - _test_.py:16:  int('abc')
"""[1:]
        if python24:
            expected = expected.replace("int() with base 10: 'abc'", 'int(): abc')
        self.do_test(desc, script, expected)


    class _MultipleErrorsTest(object):
        def setUp(self):
            pass
        def tearDown(self):
            raise RuntimeError("*** tearDown() ***")
        #
        def provide_x(self):
            @at_end
            def _():
                raise RuntimeError("*** @at_end ***")
            return "X"
        def provide_y(self):
            return "Y"
        #def release_y(self, value):
        #    raise RuntimeError("*** release_y() ***")
        #
        @test("test_1")
        def test_1(self, x, y):
            assert False, '*** failed ***'
        @test("test_2")
        def test_2(self, x, y):
            raise RuntimeError("*** test_2() ***")

    def test_multiple_errors(self):
        testclass = self._MultipleErrorsTest
        reporter = oktest.Reporter()
        runner = oktest.TestRunner(reporter)
        tr = Tracer()
        tr.trace_method(reporter, 'exit_testcase')
        runner.run_class(testclass)
        self.assertEqual(len(tr), 2)
        #
        self.assertEqual(tr[0].args[1], 'test_1')
        self.assertEqual(tr[0].args[2], oktest.ST_FAILED)
        exc_info_list = tr[0].args[3]
        assert isinstance(exc_info_list, list)
        exs = [ exc_info[1] for exc_info in exc_info_list ]
        self.assertEqual(exs[0].args, ('*** failed ***',))
        self.assertEqual(exs[1].args, ('*** @at_end ***',))
        self.assertEqual(exs[2].args, ('*** tearDown() ***',))
        self.assertEqual(len(exs), 3)
        #
        self.assertEqual(tr[1].args[1], 'test_2')
        self.assertEqual(tr[1].args[2], oktest.ST_ERROR)
        exc_info_list = tr[1].args[3]
        assert isinstance(exc_info_list, list)
        exs = [ exc_info[1] for exc_info in exc_info_list ]
        self.assertEqual(exs[0].args, ('*** test_2() ***',))
        self.assertEqual(exs[1].args, ('*** @at_end ***',))
        self.assertEqual(exs[2].args, ('*** tearDown() ***',))
        self.assertEqual(len(exs), 3)


    def test_run_without_args(self):
        desc = "run (without args)"
        script = r"""
from oktest import *
class FooTest(object):
    def test_1(self):
        ok (1+1) == 2
class BarTestCase(object):
    def test_2(self):
        ok (1+1) == 2
class BazTestCase(object):
    def test_3(self):
        ok (1+1) == 2
run()
"""[1:]
        expected = r"""
* FooTest.test_1 ... [ok]
* BarTestCase.test_2 ... [ok]
* BazTestCase.test_3 ... [ok]
"""[1:]
        self.do_test(desc, script, expected)


    def test_run_with_out_keyword_arg(self):
        desc = "run (without args)"
        script = r"""
try:
  from cStringIO import StringIO
except ImportError:
  from io import StringIO

from oktest import *
class FooTest(object):
    def test_1(self):
        ok (1+1) == 2

sio = StringIO()
run(out=sio)
ok (sio.getvalue()) == "* FooTest.test_1 ... [ok]\n"
"""[1:]
        expected = ""
        self.do_test(desc, script, expected)


    def test__min_firstlineno_of_methods(self):
        desc = "_min_firstlineno_of_methods"
        script = r"""
import oktest                  # 1
class FooTest(object):         # 2
    def test_2(self):          # 3
        pass                   # 4
    def test_1(self):          # 5
        pass                   # 6
class BarTest(FooTest):        # 7
    def test_1(self):          # 8
        pass                   # 9
class BazTest(FooTest):        # 10
    def _test_1(self):         # 11
        pass                   # 12
print(oktest._min_firstlineno_of_methods(FooTest))   #=> 3
print(oktest._min_firstlineno_of_methods(BarTest))   #=> 8
print(oktest._min_firstlineno_of_methods(BazTest))   #=> -1
"""[1:]
        expected = r"""
3
8
-1
"""[1:]
        self.do_test(desc, script, expected)



class RunnerReporter_TC(unittest.TestCase, RunnerTestHelper):
    def setUp(self):    self._setUp()
    def tearDown(self): self._tearDown()


    def test_SimpleReporter(self):
        desc = "simple reporter"
        script = r"""
from oktest import *
import sys
import unittest

class FooTest(object):
  def test_success(self):
    ok (1+1) == 2
  def test_failed(self):
    ok (1+1) == 3
  def test_error(self):
    ok (int('aaa')) == 0
  def test_nested(self):
    self._test1()
  def _test1(self):
    self._test2()
  def _test2(self):
    ok (1+1) == 0
run(FooTest)
"""[1:]
        expected = r"""
* <b>FooTest</b>: .<R>f</R><R>E</R><R>f</R>
<r>----------------------------------------------------------------------</r>
[<R>Fail</R>] FooTest > test_failed()
  File "_test_.py", line 9, in test_failed
    ok (1+1) == 3
<R>AssertionError: 2 == 3 : failed.</R>
<r>----------------------------------------------------------------------</r>
[<R>ERROR</R>] FooTest > test_error()
  File "_test_.py", line 11, in test_error
    ok (int('aaa')) == 0
<R>ValueError: invalid literal for int() with base 10: 'aaa'</R>
<r>----------------------------------------------------------------------</r>
[<R>Fail</R>] FooTest > test_nested()
  File "_test_.py", line 13, in test_nested
    self._test1()
  File "_test_.py", line 15, in _test1
    self._test2()
  File "_test_.py", line 17, in _test2
    ok (1+1) == 0
<R>AssertionError: 2 == 0 : failed.</R>
<r>----------------------------------------------------------------------</r>
## total:4, <G>pass:1</G>, <R>fail:2</R>, <R>error:1</R>, skip:0, todo:0  (0.000 sec)
"""[1:]
        if python24:
            expected = expected.replace("int() with base 10: 'aaa'", 'int(): aaa')
        os.environ['OKTEST_REPORTER'] = 'SimpleReporter'
        oktest.REPORTER = oktest.SimpleReporter
        self.do_test(desc, script, Color._colorize(expected))


    def test_report_header(self):
        desc = "simple reporter"
        script = r"""
from oktest import *
import sys
import unittest

class BarTest(unittest.TestCase):

  def test_sample1(self):
    "Sample Description 1"
    ok (0) == 1

  @test("Sample Description 2")
  def test_sample2(self):
    ok (0) == 2

  @test("Sample Description 3")
  def _(self):
    ok (0) == 3

run(BarTest)
"""[1:]
        expected = r"""
* <b>BarTest</b>: <R>f</R><R>f</R><R>f</R>
<r>----------------------------------------------------------------------</r>
[<R>Fail</R>] BarTest > test_sample1()
Sample Description 1
  File "_test_.py", line 9, in test_sample1
    ok (0) == 1
<R>AssertionError: 0 == 1 : failed.</R>
<r>----------------------------------------------------------------------</r>
[<R>Fail</R>] BarTest > test_sample2()
Sample Description 2
  File "_test_.py", line 13, in test_sample2
    ok (0) == 2
<R>AssertionError: 0 == 2 : failed.</R>
<r>----------------------------------------------------------------------</r>
[<R>Fail</R>] BarTest > 002: Sample Description 3
  File "_test_.py", line 17, in _
    ok (0) == 3
<R>AssertionError: 0 == 3 : failed.</R>
<r>----------------------------------------------------------------------</r>
## total:3, pass:0, <R>fail:3</R>, error:0, skip:0, todo:0  (0.000 sec)
"""[1:]
        os.environ['OKTEST_REPORTER'] = 'SimpleReporter'
        oktest.REPORTER = oktest.SimpleReporter
        self.do_test(desc, script, Color._colorize(expected))


    def test_base_reporter_to_set_color_automatically(self):
        klass = oktest.BaseReporter
        # __init__ doesn't set color if out is not passed
        reporter = klass()
        self.assertEqual(None, reporter._color)
        # setter sets color
        reporter = klass()
        reporter.out = sys.stdout
        self.assertEqual(True, reporter._color)
        # getter sets color
        reporter = klass()
        assert reporter.out is not None
        self.assertEqual(True, reporter._color)
        # __init__ sets color if out is passed
        reporter = klass(out=sys.stdout)
        self.assertEqual(True, reporter._color)
        # color is enabled only if out is a tty
        try:
            from cStringIO import StringIO
        except ImportError:
            from io import StringIO
        sio = StringIO()
        assert sio.isatty() == False
        oktest.config.color_enabled = False
        reporter = klass(out=sio)
        self.assertEqual(False, reporter._color)
        # color is enabled if config.color.enabled is True
        oktest.config.color_enabled = True
        reporter = klass(out=sio)
        self.assertEqual(True, reporter._color)


class Diff_TC(unittest.TestCase, RunnerTestHelper):
    def setUp(self):    self._setUp()
    def tearDown(self): self._tearDown()


    def test_diff(self):
        ### diff (oktest.DIFF = True)
        desc = "diff (oktest.DIFF = True)"
        script = r"""
from oktest import *
import oktest
oktest.DIFF = True
class FooTest(object):
    def test1(self):
       ok ('foo') == 'foo1'
    def test2(self):
       ok ("AAA\nBBB\nCCC\n") == "AAA\n888\nCCC"
    def test3(self):   # bug: [ERROR] IndexError: list index out of range
       ok ("") == "\n"
run(FooTest)
"""[1:]
        expected = r"""
* FooTest.test1 ... [NG] 'foo' == 'foo1' : failed.
   _test_.py:6: ok ('foo') == 'foo1'
--- expected 
+++ actual 
@@ -1,1 +1,1 @@
-foo1
+foo
* FooTest.test2 ... [NG] 'AAA\nBBB\nCCC\n' == 'AAA\n888\nCCC' : failed.
   _test_.py:8: ok ("AAA\nBBB\nCCC\n") == "AAA\n888\nCCC"
--- expected 
+++ actual 
@@ -1,3 +1,3 @@
 AAA
-888
-CCC
\ No newline at end of string
+BBB
+CCC
* FooTest.test3 ... [NG] '' == '\n' : failed.
   _test_.py:10: ok ("") == "\n"
--- expected 
+++ actual 
@@ -1,1 +1,1 @@
-
+
\ No newline at end of string
"""[1:]
        self.do_test(desc, script, expected)


    def test_diff_repr(self):
        ### diff (oktest.DIFF == 'repr')
        desc = "diff (oktest.DIFF == 'repr')"
        script = r"""
from oktest import *
import oktest
oktest.DIFF = repr
class FooTest(object):
    def test1(self):
        ok ('foo') == 'foo1'
    def test2(self):
        ok ("AAA\nBBB\nCCC\n") == "AAA\n888\nCCC"
run(FooTest)
"""[1:]
        expected = r"""
* FooTest.test1 ... [NG] 'foo' == 'foo1' : failed.
   _test_.py:6: ok ('foo') == 'foo1'
--- expected 
+++ actual 
@@ -1,1 +1,1 @@
-'foo1'
+'foo'
* FooTest.test2 ... [NG] 'AAA\nBBB\nCCC\n' == 'AAA\n888\nCCC' : failed.
   _test_.py:8: ok ("AAA\nBBB\nCCC\n") == "AAA\n888\nCCC"
--- expected 
+++ actual 
@@ -1,3 +1,3 @@
 'AAA\n'
-'888\n'
-'CCC'
+'BBB\n'
+'CCC\n'
"""[1:]
        self.do_test(desc, script, expected)


    def test_diff_false(self):
        ### diff (oktest.DIFF == False)
        desc = "diff (oktest.DIFF == False)"
        script = r"""
from oktest import *
import oktest
oktest.DIFF = False
class FooTest(object):
    def test1(self):
       ok ('foo') == 'foo1'
    def test2(self):
       ok ("AAA\nBBB\nCCC\n") == "AAA\n888\nCCC"
run(FooTest)
"""[1:]
        expected = r"""
* FooTest.test1 ... [NG] 'foo' == 'foo1' : failed.
   _test_.py:6: ok ('foo') == 'foo1'
* FooTest.test2 ... [NG] 'AAA\nBBB\nCCC\n' == 'AAA\n888\nCCC' : failed.
   _test_.py:8: ok ("AAA\nBBB\nCCC\n") == "AAA\n888\nCCC"
"""[1:]
        self.do_test(desc, script, expected)


    def test_diff_pformat(self):
        ### diff (using pformat)
        desc = "diff (using pformat)"
        script = r"""
from oktest import *
import oktest
class FooTest(object):
    def test1(self):
        expected = {
          'members': [
            {'name': 'Haruhi Suzumiya', 'gender': 'F', 'role': 'Leader of SOS Brigade'},
            {'name': 'Mikuru Asahina',  'gender': 'F', 'role': 'Time Traveler'},
            {'name': 'Yuki Nagato',     'gender': 'F', 'role': 'Humanoid Interface'},
          ]
        }
        actual = {
          'members': [
            {'name': 'Haruhi Suzumiya', 'gender': 'F', 'role': 'Leader of SOS Brigade'},
            {'name': 'Michiru Asahina', 'gender': 'F', 'role': 'Time Traveler'},
            {'name': 'Yuki Nagato',     'gender': 'F', 'role': 'Just an ordinary girl'},
          ]
        }
        ok (actual) == expected
run(FooTest)
"""[1:]
        expected = r"""
* FooTest.test1 ... [NG] {'members': [{'gender': 'F', 'role': 'Leader of SOS Brigade', 'name': 'Haruhi Su [truncated]... == {'members': [{'gender': 'F', 'role': 'Leader of SOS Brigade', 'name': 'Haruhi Su [truncated]... : failed.
   _test_.py:19: ok (actual) == expected
--- expected
+++ actual
@@ -3,7 +3,7 @@
               'role': 'Leader of SOS Brigade'},
              {'gender': 'F',
-              'name': 'Mikuru Asahina',
+              'name': 'Michiru Asahina',
               'role': 'Time Traveler'},
              {'gender': 'F',
               'name': 'Yuki Nagato',
-              'role': 'Humanoid Interface'}]}
\ No newline at end of string
+              'role': 'Just an ordinary girl'}]}
\ No newline at end of string
"""[1:]
        #
        callback = None
        if python33:
            pat = r'^\* FooTest\.test1 ... \[NG\].*\n'
            expected = re.sub(pat, '', expected)
            def callback(output):
                return re.sub(pat, '', output)
        #
        self.do_test(desc, script, expected, callback=callback)



if __name__ == '__main__':
    unittest.main()
