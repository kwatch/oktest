###
### $Release: $
### $Copyright: copyright(c) 2010-2012 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest
try:
    from cStringIO import StringIO
except ImportError:
    from io import StringIO

import oktest
from oktest import test
from oktest import skip
from oktest.util import Color



class Skip_TC(unittest.TestCase):


    ### skip()

    def test_skip_1(self):
        """raises SkipTest exception"""
        try:
            skip("reason")
            self.fail("SkipTest expected but not raised")
        except Exception:
            ex_class, ex = sys.exc_info()[:2]
            self.assertEqual(oktest.SkipTest, ex_class)
            self.assertEqual("reason", str(ex))


    ### skip.when()

    def test_skip_when_1(self):
        """raises SkipTest exception when condition is true"""
        @skip.when(1==1, "reason2")
        def fn(self):
            return "A"
        try:
            fn(None)
            self.fail("SkipTest expected but not raised")
        except Exception:
            ex_class, ex = sys.exc_info()[:2]
            self.assertEqual(oktest.SkipTest, ex_class)
            self.assertEqual("reason2", str(ex))

    def test_skip_when_2(self):
        """do nothing when condition is false"""
        @skip.when(1==0, "reason3")
        def fn(self):
            return "A"
        self.assertEqual("A", fn(None))


    ### Runner

    def _test_runner(self, expected, testclass):
        out = StringIO()
        kwargs = dict(style="verbose", out=out, color=True)
        n_errors = oktest.run(testclass, **kwargs)
        output = out.getvalue()
        output = re.sub('0\.\d\d\d sec', '0.000 sec', output)
        self.maxDiff = None
        oktest.ok (output) == Color._colorize(expected)
        self.assertEqual(Color._colorize(expected), output)
        self.assertEqual(0, n_errors)

    class _RunnterHandleSkipTest(object):
        def test1(self):
            skip("reason #1")
        #
        @skip.when(True, "reason #2")
        def test2(self):
            sys.exit()

    def test_runner_should_handle_SkipTest(self):
        expected = r"""
* <b>_RunnterHandleSkipTest</b>
  - [<Y>skipped</Y>] test1 (reason: reason #1)
  - [<Y>skipped</Y>] test2 (reason: reason #2)
## total:2, passed:0, failed:0, error:0, <Y>skipped:2</Y>, todo:0  (0.000 sec)
"""[1:]
        self._test_runner(expected, Skip_TC._RunnterHandleSkipTest)

    try:
        import unittest
        unittest.skip
    except AttributeError:
        pass
    else:

        class _RunnterHandleUnittestSkipTest(unittest.TestCase):
            @unittest.skip("reason1")
            def test1(self):
                self.fail("unreachable")
            #
            @unittest.skipIf(1==1, "reason2")
            def test2(self):
                self.fail("unreachable")

        def test_runner_should_handle_unittests_SkipTest(self):
            expected = r"""
* <b>_RunnterHandleUnittestSkipTest</b>
  - [<Y>skipped</Y>] test1 (reason: reason1)
  - [<Y>skipped</Y>] test2 (reason: reason2)
## total:2, passed:0, failed:0, error:0, <Y>skipped:2</Y>, todo:0  (0.000 sec)
"""[1:]
            self._test_runner(expected, Skip_TC._RunnterHandleUnittestSkipTest)

        class _AvailableWithTestDecorator(object):
            @test("desc7")
            def _(self):
                skip("reason7")
            #
            @test("desc2")
            @skip.when(1==1, "reason2")         # supported
            def _(self):
                raise Exception("xxx")
            #
            @skip.when(1==1, "reason3")         # NOT WORK!
            @test("desc3")
            def _(self):
                pass

        def test_skip_is_avaialbe_with_test_decorator(self):
            expected = r"""
* <b>_AvailableWithTestDecorator</b>
  - [<Y>skipped</Y>] desc7 (reason: reason7)
  - [<Y>skipped</Y>] desc2 (reason: reason2)
  - [<G>passed</G>] desc3
## total:3, <G>passed:1</G>, failed:0, error:0, <Y>skipped:2</Y>, todo:0  (0.000 sec)
"""[1:]
            self._test_runner(expected, Skip_TC._AvailableWithTestDecorator)



if __name__ == '__main__':
    unittest.main()
