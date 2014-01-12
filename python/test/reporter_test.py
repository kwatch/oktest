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
from oktest import ok, test, skip, todo
from oktest.context import subject, situation
from oktest.util import Color

python_command = os.environ.get('PYTHON', 'python')
python24 = sys.version_info[0:2] <= (2, 4)
def withstmt_not_available():
    if python24:
        sys.stderr.write("*** skip because with-statment is not supported\n")
        return True
    return False


filename = '_test_tmp.py'

def _do_test(code_str, **kwargs):
    ## create sandbox
    sandbox = {'unittest': unittest, 'oktest': oktest,
               'ok': ok, 'test': test, 'skip': skip, 'todo': todo,
               'subject': subject, 'situation': situation }
    ## exec python code
    code_obj = compile(code_str, filename, 'exec')
    exec(code_obj, sandbox, sandbox)
    klass = sandbox.get('_Foo_TestCase')
    ## with temporary file
    f = open(filename, 'w'); f.write(code_str); f.close()
    out = StringIO()
    try:
        oktest.run(klass, out=out, **kwargs)
    finally:
        os.unlink(filename)
    ## return output
    actual = out.getvalue()
    return re.sub(r'0\.\d\d\d sec', '0.000 sec', actual)

def _colorize(expected):
    return Color._colorize(expected)


INPUT_COMPREHENSIVE = r"""
class _Foo_TestCase(unittest.TestCase):
  SUBJECT = "class 'Foo'"

  ## passed
  @test("1+1 should be 2")
  def _(self):
    ok (1+1) == 2

  ## failed
  @test("1-1 should be 0")
  def _(self):
    ok (1-1) == 2

  ## error
  @test("length of empty list should be 0")
  def _(self):
    n = [].len
    ok (n) == 0

  ## skipped
  @test("should be skipped")
  @skip.when(1+1==2, "REASON")
  def _(self):
    fail("FAILED")

  ## todo (expected failure)
  @test("expected failure")
  @todo
  def _(self):
    ok (1+1) == 0    # expected failure

  ## todo (unexpected success)
  @test("unexpected success")
  @todo
  def _(self):
    ok (1+1) == 2    # unexpected success
"""

OUTPUT_COMPREHENSIVE = r"""
<r>----------------------------------------------------------------------</r>
[<R>Fail</R>] class 'Foo' > 002: 1-1 should be 0
  File "_test_tmp.py", line 13, in _
    ok (1-1) == 2
<R>AssertionError: 0 == 2 : failed.</R>
<r>----------------------------------------------------------------------</r>
[<R>ERROR</R>] class 'Foo' > 003: length of empty list should be 0
  File "_test_tmp.py", line 18, in _
    n = [].len
<R>AttributeError: 'list' object has no attribute 'len'</R>
<r>----------------------------------------------------------------------</r>
[<R>Fail</R>] class 'Foo' > 006: unexpected success
<R>_UnexpectedSuccess: test should be failed (because not implemented yet), but passed unexpectedly.</R>
<r>----------------------------------------------------------------------</r>
## total:6, <G>pass:1</G>, <R>fail:2</R>, <R>error:1</R>, <Y>skip:1</Y>, <Y>todo:1</Y>  (0.000 sec)
"""[1:]


INPUT_WITH_TEST_CONTEXT = r"""from __future__ import with_statement
class _Foo_TestCase(unittest.TestCase):
  with subject('module hello'):
    with subject('#method1'):
      @test('spec1')
      def _(self):
        ok (1) == 1
      with situation('when condition1:'):
        @test('spec2')
        def _(self):
          ok (2) == 2
        @test('spec3')
        def _(self):
          ok (3) == 0
      with situation('else:'):
        @test('spec4')
        def _(self):
          ok (4) == 4
"""

OUTPUT_WITH_TEST_CONTEXT = r"""
<r>----------------------------------------------------------------------</r>
[<R>Fail</R>] _Foo_TestCase > module hello > #method1 > when condition1: > 003: spec3
  File "_test_tmp.py", line 14, in _
    ok (3) == 0
<R>AssertionError: 3 == 0 : failed.</R>
<r>----------------------------------------------------------------------</r>
## total:4, <G>pass:3</G>, <R>fail:1</R>, error:0, skip:0, todo:0  (0.000 sec)
"""[1:]


INPUT_FOR_MULTIPLE_ERRORS = r"""
from oktest import *
class _Foo_TestCase(unittest.TestCase):
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
    def release_y(self, value):
        raise RuntimeError("*** release_y() ***")
    #
    @test("test_1")
    def test_1(self, x, y):
        assert False
    @test("test_2")
    def test_2(self, x, y):
        raise RuntimeError("*** test_2() ***")
"""[1:]

EXPECTED_FOR_MULTIPLE_ERRORS = r"""
----------------------------------------------------------------------
[ERROR] _Foo_TestCase > test_1()
test_1
  File "_test_tmp.py", line 16, in release_y
    raise RuntimeError("*** release_y() ***")
RuntimeError: *** release_y() ***
----------------------------------------------------------------------
[ERROR] _Foo_TestCase > test_1()
test_1
  File "_test_tmp.py", line 11, in _
    raise RuntimeError("*** @at_end ***")
RuntimeError: *** @at_end ***
----------------------------------------------------------------------
[ERROR] _Foo_TestCase > test_1()
test_1
  File "_test_tmp.py", line 6, in tearDown
    raise RuntimeError("*** tearDown() ***")
RuntimeError: *** tearDown() ***
----------------------------------------------------------------------
[ERROR] _Foo_TestCase > test_2()
test_2
  File "_test_tmp.py", line 16, in release_y
    raise RuntimeError("*** release_y() ***")
RuntimeError: *** release_y() ***
----------------------------------------------------------------------
[ERROR] _Foo_TestCase > test_2()
test_2
  File "_test_tmp.py", line 11, in _
    raise RuntimeError("*** @at_end ***")
RuntimeError: *** @at_end ***
----------------------------------------------------------------------
[ERROR] _Foo_TestCase > test_2()
test_2
  File "_test_tmp.py", line 6, in tearDown
    raise RuntimeError("*** tearDown() ***")
RuntimeError: *** tearDown() ***
----------------------------------------------------------------------
## total:2, pass:0, fail:0, error:2, skip:0, todo:0  (0.000 sec)
"""[1:]


class VerboseReporter_TC(unittest.TestCase):


    def test_comprehensive(self):
        input = INPUT_COMPREHENSIVE
        expected = r"""
* <b>class 'Foo'</b>
  - [<G>pass</G>] 1+1 should be 2
  - [<R>Fail</R>] 1-1 should be 0
  - [<R>ERROR</R>] length of empty list should be 0
  - [<Y>skip</Y>] should be skipped (reason: REASON)
  - [<Y>TODO</Y>] expected failure
  - [<R>Fail</R>] unexpected success
"""[1:] + OUTPUT_COMPREHENSIVE
        actual = _do_test(input, color=True, style="verbose")
        ok (actual) == _colorize(expected)


    def test_with_test_context(self):
        if withstmt_not_available(): return
        input = INPUT_WITH_TEST_CONTEXT
        expected = r"""
* <b>_Foo_TestCase</b>
  + <b>module hello</b>
    + <b>#method1</b>
      - [<G>pass</G>] spec1
      + when condition1:
        - [<G>pass</G>] spec2
        - [<R>Fail</R>] spec3
      + else:
        - [<G>pass</G>] spec4
"""[1:] + OUTPUT_WITH_TEST_CONTEXT
        actual = _do_test(input, color=True, style="verbose")
        ok (actual) == _colorize(expected)


    def test_when_multiple_errors(self):
        input = INPUT_FOR_MULTIPLE_ERRORS
        expected = r"""
* _Foo_TestCase
  - [ERROR] test_1
  - [ERROR] test_2
"""[1:] + EXPECTED_FOR_MULTIPLE_ERRORS
        actual = _do_test(input, color=False, style="verbose")
        ok (actual) == expected



class SimpleReporter_TC(unittest.TestCase):


    def test_comprehensive(self):
        input = INPUT_COMPREHENSIVE
        expected = r"""
* <b>class 'Foo'</b>: .<R>f</R><R>E</R><Y>s</Y><Y>t</Y><R>f</R>
"""[1:] + OUTPUT_COMPREHENSIVE
        actual = _do_test(input, color=True, style="simple")
        ok (actual) == _colorize(expected)


    def test_with_test_context(self):
        if withstmt_not_available(): return
        input = INPUT_WITH_TEST_CONTEXT
        expected = r"""
* <b>_Foo_TestCase</b>: ..<R>f</R>.
"""[1:]  + OUTPUT_WITH_TEST_CONTEXT
        actual = _do_test(input, color=True, style="simple")
        ok (actual) == _colorize(expected)

    def test_when_multiple_errors(self):
        input = INPUT_FOR_MULTIPLE_ERRORS
        expected = r"""
* _Foo_TestCase: EE
"""[1:] + EXPECTED_FOR_MULTIPLE_ERRORS
        actual = _do_test(input, color=False, style="simple")
        ok (actual) == expected



class PlainReporter_TC(unittest.TestCase):


    def test_comprehensive(self):
        input = INPUT_COMPREHENSIVE
        expected = r"""
.<R>f</R><R>E</R><Y>s</Y><Y>t</Y><R>f</R>
"""[1:] + OUTPUT_COMPREHENSIVE
        expected = expected.replace("## total:", "\n## total:")     # necessary?
        actual = _do_test(input, color=True, style="plain")
        ok (actual) == _colorize(expected)


    def test_with_test_context(self):
        if withstmt_not_available(): return
        input = INPUT_WITH_TEST_CONTEXT
        expected = r"""
..<R>f</R>.
"""[1:] + OUTPUT_WITH_TEST_CONTEXT
        expected = expected.replace("## total:", "\n## total:")     # necessary?
        actual = _do_test(input, color=True, style="plain")
        ok (actual) == _colorize(expected)


    def test_when_multiple_errors(self):
        input = INPUT_FOR_MULTIPLE_ERRORS
        expected = r"""
EE
"""[1:] + EXPECTED_FOR_MULTIPLE_ERRORS
        expected = expected.replace("\n## ", "\n\n## ")   # TODO
        actual = _do_test(input, color=False, style="plain")
        ok (actual) == expected



if __name__ == '__main__':
    unittest.main()
