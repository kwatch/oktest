###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest
try:
    from cStringIO import StringIO
except ImportError:
    from io import StringIO

import oktest
from oktest import ok, test
from oktest import todo, _ExpectedFailure, _UnexpectedSuccess



class Todo_TC(unittest.TestCase):


    ### @todo()

    def test_todo_1(self):
        """
        test method decorated by @todo should raises _ExpectedFailure exception
        with assertion information when it failed expectedly.
        """
        @todo
        def fn(self):
            assert 1+1 == 0, "DESC1"
        try:
            fn(self)
            self.fail("_ExpectedFailure expected but not raised")
        except Exception:
            ex = sys.exc_info()[1]
            assert isinstance(ex, _ExpectedFailure)
            assert isinstance(ex.exc_info, tuple)
            assert len(ex.exc_info) == 3
            assert ex.exc_info[0] == AssertionError
            assert str(ex.exc_info[1]) == "DESC1"

    def test_todo_2(self):
        """
        test method decorated by @todo should raises _UnExpectedSuccess exception
        without assertion information when it passed unexpectedly.
        """
        @todo
        def fn(self):
            assert 1+1 == 2, "DESC1"
        try:
            fn(self)
            self.fail("_UnexpectedSuccess expected but not raised")
        except Exception:
            ex = sys.exc_info()[1]
            assert isinstance(ex, _UnexpectedSuccess)
            assert not hasattr(ex, 'exc_info')


    ### Runner

    def _test_runner(self, expected, testclass, expected_n_errors=0):
        out = StringIO()
        kwargs = dict(style="verbose", out=out, color=True)
        n_errors = oktest.run(testclass, **kwargs)
        output = out.getvalue()
        output = re.sub('0\.\d\d\d sec', '0.000 sec', output)
        ok (output) == oktest.Color._colorize(expected)
        self.maxDiff = None
        self.assertEqual(oktest.Color._colorize(expected), output)
        self.assertEqual(expected_n_errors, n_errors)

    class _RunnerHandleExpectedFailureTest(object):
        @todo
        def test1(self):
            assert 1 == 0, "DESC1"    # expected failure
        #
        @todo
        def test2(self):
            assert 1 == 1, "DESC2"    # unexpected success

    def test_runner_should_handle_ExpectedFailure(self):
        expected = r"""
* <b>_RunnerHandleExpectedFailureTest</b>
  - [<Y>TODO</Y>] test1
  - [<R>Failed</R>] test2
<r>----------------------------------------------------------------------</r>
[<R>Failed</R>] _RunnerHandleExpectedFailureTest > test2()
<R>_UnexpectedSuccess: test should be failed (because not implemented yet), but passed unexpectedly.</R>
<r>----------------------------------------------------------------------</r>
## total:2, passed:0, <R>failed:1</R>, error:0, skipped:0, <Y>todo:1</Y>  (0.000 sec)
"""[1:]
        self._test_runner(expected, Todo_TC._RunnerHandleExpectedFailureTest, 1)

    try:
        import unittest
        unittest.case._ExpectedFailure
    except AttributeError:
        pass
    else:

        class _RunnerHandleUnittestExpectedFailure(unittest.TestCase):
            @unittest.expectedFailure
            def test1(self):
                assert 1 == 0, "expected failure"
            @unittest.expectedFailure
            def test2(self):
                assert 1 == 1, "unexpected success"

        def test_runner_should_handle_unittests_ExpectedFailure(self):
            expected = r"""
* <b>_RunnerHandleUnittestExpectedFailure</b>
  - [<Y>TODO</Y>] test1
  - [<R>Failed</R>] test2
<r>----------------------------------------------------------------------</r>
[<R>Failed</R>] _RunnerHandleUnittestExpectedFailure > test2()
<R>_UnexpectedSuccess: test should be failed (because not implemented yet), but passed unexpectedly.</R>
<r>----------------------------------------------------------------------</r>
## total:2, passed:0, <R>failed:1</R>, error:0, skipped:0, <Y>todo:1</Y>  (0.000 sec)
"""[1:]
            self._test_runner(expected, Todo_TC._RunnerHandleUnittestExpectedFailure, 1)

        class _TodoIsAvailableWithTestDecorator(object):
            @test("SPEC1")
            @todo
            def _(self):
                assert 1 == 0, "expected failure"
            #
            @test("SPEC2")
            @todo
            def _(self):
                assert 1 == 1, "unexpected success"
            #
            @todo         # NOT WORK!
            @test("SPEC3")
            def _(self):
                assert 1 == 0, "expected failure"
            #
            @todo         # NOT WORK!
            @test("SPEC4")
            def _(self):
                assert 1 == 1, "unexpected success"

        def test_todo_is_avaialbe_with_test_decorator(self):
            expected = r"""
* <b>_TodoIsAvailableWithTestDecorator</b>
  - [<R>Failed</R>] SPEC3
  - [<G>passed</G>] SPEC4
  - [<Y>TODO</Y>] SPEC1
  - [<R>Failed</R>] SPEC2
<r>----------------------------------------------------------------------</r>
[<R>Failed</R>] _TodoIsAvailableWithTestDecorator > 003: SPEC3
  File "test/todo_test.py", line 138, in _
    assert 1 == 0, "expected failure"
<R>AssertionError: expected failure</R>
<r>----------------------------------------------------------------------</r>
[<R>Failed</R>] _TodoIsAvailableWithTestDecorator > 002: SPEC2
<R>_UnexpectedSuccess: test should be failed (because not implemented yet), but passed unexpectedly.</R>
<r>----------------------------------------------------------------------</r>
## total:4, <G>passed:1</G>, <R>failed:2</R>, error:0, skipped:0, <Y>todo:1</Y>  (0.000 sec)
"""[1:]
            self._test_runner(expected, Todo_TC._TodoIsAvailableWithTestDecorator, 2)



if __name__ == '__main__':
    unittest.main()