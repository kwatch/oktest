###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###
from __future__ import with_statement

import sys, os, re
import unittest

import oktest
from oktest import ok, run, spec, Spec

with_stmt_available = sys.version_info >= (2, 5,)


class Spec_TC(unittest.TestCase):

    def test___init__(self):
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
        try:
            obj.__enter__()
            ok (1+1) == 0
        except:
            ret = obj.__exit__(*sys.exc_info())
        ex = sys.exc_info()[1]
        assert ret == True
        assert obj._exception == sys.exc_info()[1]
        assert obj._traceback == sys.exc_info()[2]
        assert obj._stacktrace
        assert isinstance(obj._stacktrace, list)

    def test_spec(self):
        obj = spec("SOS")
        assert isinstance(obj, Spec)
        assert obj.desc == "SOS"


class Spec_TestScenario_TC(unittest.TestCase):

    def _run_oktest(self, file_name, content):
        f = open(file_name, 'w')
        f.write(content)
        f.close()
        command = "%s %s" % (sys.executable, file_name)
        try:
            stdin, stdout, stderr = os.popen3(command)
            stdin.close()
            sout = stdout.read(); stdout.close()
            serr = stderr.read(); stderr.close()
            return sout, serr
        finally:
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
### FooTest
ff
Failed: FooTest#test_1()
  2 == 1 : failed.
  File "__test_scenario1.py", line 8, in test_1
    ok (1+1) == 1
Failed: FooTest#test_1()
  0 == 1 : failed.
  File "__test_scenario1.py", line 10, in test_1
    ok (1-1) == 1
"""[1:]
        expected2 = r"""
### FooTest
f
Failed: FooTest#test_1()
  2 == 1 : failed.
  File "__test_scenario1.py", line 8, in test_1
    ok (1+1) == 1
"""[1:]
        fname = "__test_scenario1.py"
        ## with with-stmt
        if with_stmt_available:
            sout, serr = self._run_oktest(fname, input)
            assert sout == expected1
            assert serr == ""
        ## without with-stmt
        if True:
            input2 = input.replace('with spec', '#with spec')
            sout, serr = self._run_oktest(fname, input2)
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
  if boolean != self.expected:
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
### FooTest
ff
Failed: FooTest#test1()
  2 == 0 : failed.
  File "__test_scenario2.py", line 13, in test1
    self._m2()
  File "__test_scenario2.py", line 15, in _m2
    self._m3()
  File "__test_scenario2.py", line 18, in _m3
    ok (1+1) == 0
Failed: FooTest#test1()
  'KYON'.startswith('ky') : failed.
  File "__test_scenario2.py", line 13, in test1
    self._m2()
  File "__test_scenario2.py", line 15, in _m2
    self._m3()
  File "__test_scenario2.py", line 21, in _m3
    ok ("KYON").starts_with("ky")
"""[1:]
        expected2 = r"""
### FooTest
f
Failed: FooTest#test1()
  2 == 0 : failed.
  File "__test_scenario2.py", line 13, in test1
    self._m2()
  File "__test_scenario2.py", line 15, in _m2
    self._m3()
  File "__test_scenario2.py", line 18, in _m3
    ok (1+1) == 0
"""[1:]
        fname = "__test_scenario2.py"
        ## with with-statement
        if with_stmt_available:
            sout, serr = self._run_oktest(fname, input)
            assert sout == expected1
            assert serr == ""
        ## without with-statement
        if True:
            input2 = input.replace('with spec', '#with spec')
            sout, serr = self._run_oktest(fname, input2)
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
### FooTest
E
ERROR: FooTest#test1()
  AttributeError: 'NoneType' object has no attribute 'unknownattribute'
  File "__test_scenario3.py", line 7, in test1
    self._m2()
  File "__test_scenario3.py", line 9, in _m2
    self._m3()
  File "__test_scenario3.py", line 15, in _m3
    None.unknownattribute
"""[1:]
        expected2 = expected1
        fname = "__test_scenario3.py"
        ## with with-statement
        if with_stmt_available:
            sout, serr = self._run_oktest(fname, input)
            assert sout == expected1
            assert serr == ""
        ## without with-statement
        if True:
            input2 = input.replace('with spec', '#with spec') \
                          .replace('ok (1+1) == 0', '#ok (1+1) == 0')
            sout, serr = self._run_oktest(fname, input2)
            assert sout == expected2
            assert serr == ""


if __name__ == '__main__':
    unittest.main()
