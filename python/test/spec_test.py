###
### $Release: $
### $Copyright: copyright(c) 2010-2012 kuwata-lab.com all rights reserved $
### $License: MIT License $
###
#from __future__ import with_statement

import sys, os, re
import unittest

import oktest
from oktest import ok, run
from oktest import spec, Spec
from oktest.util import Color
os.environ['OKTEST_WARNING_DISABLED'] = 'true'

with_stmt_available = sys.version_info >= (2, 5,)

python3 = sys.version_info[0] == 3

def replace_with_stmt(content):
    content = content.replace('with spec', '#with spec')
    content = content.replace('from __future__', '#from __future__')
    return content


class Spec_TC(unittest.TestCase):

    def test___init__(self):
        """takes description."""
        assert Spec("SOS").desc == "SOS"

    def test___enter__(self):
        obj = Spec("SOS")
        self.__dict__.pop('_run_by_oktest', None)
        self.__dict__.pop('_okest_specs', None)
        ret = obj.__enter__()
        assert ret is obj
        assert obj._testcase is self
        #
        obj = Spec("SOS")
        self._run_by_oktest = True
        self._oktest_specs = []
        ret = obj.__enter__()
        assert ret is obj
        assert obj._testcase is self
        assert self._oktest_specs == [obj]

    def test___exit__(self):
        ## not run by oktest
        obj = Spec("SOS")
        self.__dict__.pop('_run_by_oktest', None)
        self.__dict__.pop('_okest_specs', None)
        try:
            obj.__enter__()
            ok (1+1) == 0
        except:
            ret = obj.__exit__(*sys.exc_info())
        assert ret == None
        assert obj._exception == None
        assert obj._traceback == None
        assert obj._stacktrace == None
        ## run by oktset
        obj = Spec("SOS")
        self._run_by_oktest = True
        self._oktest_specs = []
        ret = arr = None
        try:
            obj.__enter__()
            ok (1+1) == 0
        except:
            arr = sys.exc_info()
            ret = obj.__exit__(*arr)
            del self._oktest_specs
        ex = sys.exc_info()[1]   # exception object in Python2, None in Python3
        assert ret == True
        assert isinstance(arr, tuple)
        assert obj._exception == arr[1]
        assert obj._traceback == arr[2]
        assert obj._stacktrace
        assert isinstance(obj._stacktrace, list)

    def test___iter___1(sefl):
        """emulates with-stmt when used with for-stmt."""
        called = []
        def enter(*args):
            called.append(('enter', args))
        def exit(*args):
            called.append(('exit', args))
        obj = Spec('foo')
        obj.__enter__ = enter
        obj.__exit__  = exit
        i = 0
        for x in obj:
            i += 1
            called.append(('yield', x))
            ok (x).is_(obj)
        ok (i) == 1
        ok (called[0]) == ('enter', ())
        ok (called[1]) == ('yield', obj)
        ok (called[2]) == ('exit', (None, None, None))

    def test___call___1(self):
        """emulates with-stmt when called as decorator."""
        arr = []
        def fn():
            obj = Spec('foo')
            @obj
            def _():
                arr.append("before")
                ok (1+1) == 2     # passed
                arr.append("after")
        ok (fn).not_raise()
        ok (arr) == ["before", "after"]

    def test___call___2(self):
        """emulates with-stmt when called as decorator."""
        arr = []
        def fn():
            obj = Spec('foo')
            @obj
            def _():
                arr.append("before")
                ok (1+1) == 1    # failed
                arr.append("after")
        ok (fn).raises(AssertionError, "2 == 1 : failed.")
        ok (arr) == ["before"]
        #
        if hasattr(self, '_oktest_specs'):
            self._oktest_specs[:] = []

    def test___bool___1(self):
        """returns True when $SPEC is not set."""
        obj = Spec('SOS')
        ok (bool(obj)) == True

    def test___bool___2(self):
        """returns False when $SPEC not matched to SPEC."""
        obj = Spec('SOS')
        try:
            os.environ['SPEC'] = 'SOS'
            ok (bool(obj)) == True
            os.environ['SPEC'] = 'SOS!'
            ok (bool(obj)) == False
            os.environ['SPEC'] = 'OS'
            ok (bool(obj)) == True
        finally:
            os.environ.pop('SPEC')


    def test_spec_1(self):
        """returns oktest.Spec object."""
        obj = spec('Haruhi')
        ok (obj).is_a(Spec)

    def test_spec_2(self):
        """takes description."""
        obj = spec('Haruhi')
        ok (obj.desc) == 'Haruhi'


try:
    import subprocess

    def _system(command):
        try:
            from subprocess import Popen, PIPE
            pipe = Popen(command, shell=True, stdin=PIPE, stdout=PIPE, stderr=PIPE,
                         close_fds=True, universal_newlines=True)
            stdin, stdout, stderr = pipe.stdin, pipe.stdout, pipe.stderr
            stdin.close()
            sout = stdout.read()
            serr = stderr.read()
            return sout, serr
        finally:
            stdout.close()
            stderr.close()

except ImportError:

    import popen2

    def _system(command):
        stdin, stdout, stderr = popen2.popen3(command)
        try:
            stdin.close()
            sout = stdout.read()
            serr = stderr.read()
            return sout, serr
        finally:
            stdout.close()
            stderr.close()


class Spec_TestScenario_TC(unittest.TestCase):

    def _run_oktest(self, file_name, content):
        f = open(file_name, 'w')
        f.write(content)
        f.close()
        command = "%s %s" % (sys.executable, file_name)
        key = 'OKTEST_REPORTER'
        bkup = os.environ.get(key)
        try:
            os.environ[key] = 'SimpleReporter'
            sout, serr = _system(command)
            return sout, serr
        finally:
            if bkup: os.environ[key] = bkup
            if os.path.exists(file_name):
                os.unlink(file_name)

    def test_that_one_method_has_some_failed_specs(self):
        input = r"""
from __future__ import with_statement
import oktest
from oktest import ok, spec

class FooTest(object):
  def test_1(self):  # one method has some failed specs
    with spec("1+1 should be 2."):   # fail
      ok (1+1) == 1
    with spec("1-1 should be 0."):   # fail
      ok (1-1) == 1

oktest.run()
"""[1:]
        expected1 = r"""
* FooTest: f
----------------------------------------------------------------------
[Failed] FooTest > test_1() > 1+1 should be 2.
  File "__test_scenario1.py", line 8, in test_1
    ok (1+1) == 1
AssertionError: 2 == 1 : failed.
----------------------------------------------------------------------
[Failed] FooTest > test_1() > 1-1 should be 0.
  File "__test_scenario1.py", line 10, in test_1
    ok (1-1) == 1
AssertionError: 0 == 1 : failed.
----------------------------------------------------------------------
## total:1, passed:0, failed:1, error:0, skipped:0, todo:0  (0.000 sec)
"""[1:]
        expected2 = r"""
* FooTest: f
----------------------------------------------------------------------
[Failed] FooTest > test_1()
  File "__test_scenario1.py", line 8, in test_1
    ok (1+1) == 1
AssertionError: 2 == 1 : failed.
----------------------------------------------------------------------
## total:1, passed:0, failed:1, error:0, skipped:0, todo:0  (0.000 sec)
"""[1:]
        expected1 = Color._colorize(expected1)
        expected2 = Color._colorize(expected2)
        fname = "__test_scenario1.py"
        ## with with-stmt
        if with_stmt_available:
            sout, serr = self._run_oktest(fname, input)
            sout = re.sub(r'0.\d\d\d sec', '0.000 sec', sout)
            self.assertEqual("", serr)
            from oktest import ok; ok (sout) == expected1
            self.assertEqual(expected1, sout)
            assert sout == expected1
            assert serr == ""
        ## without with-stmt
        if True:
            input2 = replace_with_stmt(input)   # remove 'with' statement
            sout, serr = self._run_oktest(fname, input2)
            sout = re.sub(r'0.\d\d\d sec', '0.000 sec', sout)
            assert sout == expected2
            assert serr == ""

    def test_that_correct_traceback_is_displayed_when_assertion_failed(self):
        input = r"""
from __future__ import with_statement
import oktest
from oktest import ok, spec

@oktest.assertion
def starts_with(self, arg):
  boolean = self.target.startswith(arg)
  if boolean != self.boolean:
    self.failed("%r.startswith(%r) : failed." % (self.target, arg))

class FooTest(object):
  def test1(self):
    self._m2()
  def _m2(self):
    self._m3()
  def _m3(self):
    with spec("1+1 is 2"):
      ok (1+1) == 0
      pass
    with spec("'KYON' starts with 'KY'"):
      ok ("KYON").starts_with("ky")
      pass

oktest.run()
"""[1:]
        expected1 = r"""
* FooTest: f
----------------------------------------------------------------------
[Failed] FooTest > test1() > 1+1 is 2
  File "__test_scenario2.py", line 13, in test1
    self._m2()
  File "__test_scenario2.py", line 15, in _m2
    self._m3()
  File "__test_scenario2.py", line 18, in _m3
    ok (1+1) == 0
AssertionError: 2 == 0 : failed.
----------------------------------------------------------------------
[Failed] FooTest > test1() > 'KYON' starts with 'KY'
  File "__test_scenario2.py", line 13, in test1
    self._m2()
  File "__test_scenario2.py", line 15, in _m2
    self._m3()
  File "__test_scenario2.py", line 21, in _m3
    ok ("KYON").starts_with("ky")
AssertionError: 'KYON'.startswith('ky') : failed.
----------------------------------------------------------------------
## total:1, passed:0, failed:1, error:0, skipped:0, todo:0  (0.000 sec)
"""[1:]
        expected2 = r"""
* FooTest: f
----------------------------------------------------------------------
[Failed] FooTest > test1()
  File "__test_scenario2.py", line 13, in test1
    self._m2()
  File "__test_scenario2.py", line 15, in _m2
    self._m3()
  File "__test_scenario2.py", line 18, in _m3
    ok (1+1) == 0
AssertionError: 2 == 0 : failed.
----------------------------------------------------------------------
## total:1, passed:0, failed:1, error:0, skipped:0, todo:0  (0.000 sec)
"""[1:]
        expected1 = Color._colorize(expected1)
        expected2 = Color._colorize(expected2)
        fname = "__test_scenario2.py"
        ## with with-statement
        if with_stmt_available:
            sout, serr = self._run_oktest(fname, input)
            sout = re.sub(r'0.\d\d\d sec', '0.000 sec', sout)
            assert sout == expected1
            assert serr == ""
        ## without with-statement
        if True:
            input2 = replace_with_stmt(input)
            sout, serr = self._run_oktest(fname, input2)
            sout = re.sub(r'0.\d\d\d sec', '0.000 sec', sout)
            ok (sout) == expected2
            ok (serr) == ""
            assert sout == expected2
            assert serr == ""

    def test_that_correct_traceback_is_displayed_when_error_raised(self):
        input = r"""
from __future__ import with_statement
import oktest
from oktest import ok, spec

class FooTest(object):
  def test1(self):
    self._m2()
  def _m2(self):
    self._m3()
  def _m3(self):
    with spec("1+1 is 2"):
      ok (1+1) == 0       # failed but not reported because of the following error
      pass
    with spec("'KYON' starts with 'KY'"):
      None.unknownattribute
      pass

oktest.run()
"""[1:]
        expected1 = r"""
* FooTest: E
----------------------------------------------------------------------
[ERROR] FooTest > test1()
  File "__test_scenario3.py", line 7, in test1
    self._m2()
  File "__test_scenario3.py", line 9, in _m2
    self._m3()
  File "__test_scenario3.py", line 15, in _m3
    None.unknownattribute
AttributeError: 'NoneType' object has no attribute 'unknownattribute'
----------------------------------------------------------------------
## total:1, passed:0, failed:0, error:1, skipped:0, todo:0  (0.000 sec)
"""[1:]
        expected2 = expected1
        expected1 = Color._colorize(expected1)
        expected2 = Color._colorize(expected2)
        fname = "__test_scenario3.py"
        ## with with-statement
        if with_stmt_available:
            sout, serr = self._run_oktest(fname, input)
            sout = re.sub(r'0.\d\d\d sec', '0.000 sec', sout)
            assert sout == expected1
            assert serr == ""
        ## without with-statement
        if True:
            input2 = replace_with_stmt(input)
            input2 = input2.replace('ok (1+1) == 0', '#ok (1+1) == 0')
            sout, serr = self._run_oktest(fname, input2)
            sout = re.sub(r'0.\d\d\d sec', '0.000 sec', sout)
            assert sout == expected2
            assert serr == ""


if __name__ == '__main__':
    unittest.main()
