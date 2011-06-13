###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest

import oktest
from oktest import ok, not_ok, NG
from oktest.dummy import dummy_io

echo = sys.stdout.write
python_command = os.environ.get('PYTHON', 'python')
python24 = sys.version_info[0:2] == (2, 4)

try:
    from cStringIO import StringIO
except ImportError:
    from io import StringIO



class RunnerTestHelper(object):

    sys_stdout      = sys.stdout
    sys_stderr      = sys.stderr
    oktest_OUT      = oktest.OUT
    oktest_REPORTER = oktest.REPORTER
    oktest_DIFF     = oktest.DIFF

    def _setUp(self):
        self.filename = '_test_.py'
        oktest.OUT = sys.stdout = sys.stderr = StringIO()
        oktest.REPORTER = oktest.OldStyleReporter

    def _tearDown(self):
        sys.stdout = self.sys_stdout
        sys.stderr = self.sys_stderr
        oktest.OUT = self.oktest_OUT
        oktest.REPORTER = self.oktest_REPORTER
        oktest.DIFF = self.oktest_DIFF
        if os.path.exists(self.filename):
            os.unlink(self.filename)

    def do_test(self, desc, script, expected,  _pat=re.compile(r'0\.00[\d]s')):
        f = open(self.filename, 'w'); f.write(script); f.close()
        gvars = {}
        code = compile(script, self.filename, "exec")
        exec(code, gvars, gvars)
        output = oktest.OUT.getvalue()
        #
        if isinstance(output, str):
            output = re.sub(r' at 0x[0-9a-f]{6,9}', '', output)
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
            #ver = sys.version_info[0:3]
            #if (2,7,2) <= ver < (3,2,0):
            #    expected = expected.replace('@@ -1,1 +1,1 @@', '@@ -1 +1 @@')
            #oktest.DIFF = repr
            #ok (output) == expected
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
    def before(self):
        print('before() called.')
    def after(self):
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
* FooTest.test_1 ... before() called.
test_1() called.
[ok]
after() called.
* FooTest.test_2 ... before() called.
test_2() called.
[NG] 2 == 3 : failed.
   _test_.py:19: ok (1+1) == 3
after() called.
* FooTest.test_3 ... before() called.
test_3() called.
[ERROR] ValueError: invalid literal for int() with base 10: 'abc'
  - _test_.py:22:  int('abc')
after() called.
after_all() called.
"""[1:]
        if python24:
            expected = expected.replace("int() with base 10: 'abc'", 'int(): abc')
        self.do_test(desc, script, expected)


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
[ok]
tearDown() called.
* FooTest.test_2 ... setUp() called.
test_2() called.
[NG] 2 == 3 : failed.
   _test_.py:13: ok (1+1) == 3
tearDown() called.
* FooTest.test_3 ... setUp() called.
test_3() called.
[ERROR] ValueError: invalid literal for int() with base 10: 'abc'
  - _test_.py:16:  int('abc')
tearDown() called.
"""[1:]
        if python24:
            expected = expected.replace("int() with base 10: 'abc'", 'int(): abc')
        self.do_test(desc, script, expected)


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
sys.stderr = sys.stdout
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
### FooTest: .fEf
======================================================================
Failed: FooTest#test_failed()
----------------------------------------------------------------------
  File "_test_.py", line 9, in test_failed
    ok (1+1) == 3
AssertionError: 2 == 3 : failed.

======================================================================
ERROR: FooTest#test_error()
----------------------------------------------------------------------
  File "_test_.py", line 11, in test_error
    ok (int('aaa')) == 0
ValueError: invalid literal for int() with base 10: 'aaa'

======================================================================
Failed: FooTest#test_nested()
----------------------------------------------------------------------
  File "_test_.py", line 13, in test_nested
    self._test1()
  File "_test_.py", line 15, in _test1
    self._test2()
  File "_test_.py", line 17, in _test2
    ok (1+1) == 0
AssertionError: 2 == 0 : failed.

"""[1:]
        if python24:
            expected = expected.replace("int() with base 10: 'aaa'", 'int(): aaa')
        os.environ['OKTEST_REPORTER'] = 'SimpleReporter'
        oktest.REPORTER = oktest.SimpleReporter
        self.do_test(desc, script, expected)



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



if __name__ == '__main__':
    unittest.main()
